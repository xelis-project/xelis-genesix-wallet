import 'dart:async';
import 'dart:collection';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:flutter/foundation.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/domain/authentication_state.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/domain/event.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/features/wallet/domain/wallet_snapshot.dart';
import 'package:genesix/features/logger/logger.dart';

part 'wallet_provider.g.dart';

@riverpod
class WalletState extends _$WalletState {
  @override
  WalletSnapshot build() {
    final authenticationState = ref.watch(authenticationProvider);

    switch (authenticationState) {
      case SignedIn(:final name, :final nativeWallet):
        return WalletSnapshot(
          name: name,
          nativeWalletRepository: nativeWallet,
          address: nativeWallet.address,
          network: nativeWallet.network,
          trackedBalances: LinkedHashMap.from({}),
          knownAssets: LinkedHashMap.from({}),
        );
      case SignedOut():
        return WalletSnapshot(
          trackedBalances: LinkedHashMap.from({}),
          knownAssets: LinkedHashMap.from({}),
        );
    }
  }

  Future<void> connect() async {
    if (state.nativeWalletRepository != null) {
      final loc = ref.read(appLocalizationsProvider);

      if (await state.nativeWalletRepository!.isOnline) {
        talker.info(
          'Already connected, stopping connection and reconnecting...',
        );
        await disconnect();
      }

      if (!kIsWeb) {
        // Web does not support XSWD protocol
        final enableXswd = ref.read(
          settingsProvider.select((s) => s.enableXswd),
        );
        if (enableXswd) {
          startXSWD();
        } else {
          stopXSWD();
        }
      }

      StreamSubscription<void> sub = state.nativeWalletRepository!
          .convertRawEvents()
          .listen(_onEvent);
      state = state.copyWith(streamSubscription: sub);

      final settings = ref.read(settingsProvider);
      final networkNodes = ref.read(networkNodesProvider);
      var node = networkNodes.getNodeAddress(settings.network);

      try {
        await state.nativeWalletRepository!.setOnline(daemonAddress: node.url);
      } on AnyhowException catch (e) {
        talker.warning('Cannot connect to node: ${e.message}');
        final xelisMessage = (e).message.split("\n")[0];
        ref
            .read(snackBarQueueProvider.notifier)
            .showError(
              '${loc.cannot_connect_toast_error.replaceFirst(RegExp(r'\.'), ':')}\n$xelisMessage',
            );
      } catch (e) {
        talker.warning('Cannot connect to node: $e');
        ref
            .read(snackBarQueueProvider.notifier)
            .showError(
              '${loc.cannot_connect_toast_error.replaceFirst(RegExp(r'\.'), ':')}\n$e',
            );
      }

      try {
        final multisig = await state.nativeWalletRepository!.getMultisigState();
        if (multisig != null) state = state.copyWith(multisigState: multisig);

        final xelisBalance = await state.nativeWalletRepository!
            .getXelisBalance();
        final balances = await state.nativeWalletRepository!
            .getTrackedBalances();
        final knownAssets = await state.nativeWalletRepository!
            .getKnownAssets();

        state = state.copyWith(
          xelisBalance: xelisBalance,
          trackedBalances: sortMapByKey(balances),
          knownAssets: sortMapByKey(knownAssets),
        );
      } catch (e) {
        talker.error('Cannot retrieve wallet data: $e');
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(isOnline: false);

    try {
      await state.nativeWalletRepository?.setOffline();
    } catch (e) {
      talker.warning('Something went wrong when disconnecting: $e');
    }

    try {
      await state.nativeWalletRepository?.close();
    } catch (e) {
      talker.warning('Something went wrong when closing wallet: $e');
    }

    await state.streamSubscription?.cancel();
  }

  void reconnect([NodeAddress? nodeAddress]) {
    if (nodeAddress != null) {
      final settings = ref.read(settingsProvider);
      ref
          .read(networkNodesProvider.notifier)
          .setNodeAddress(settings.network, nodeAddress);
    }
    unawaited(connect());
  }

  Future<void> rescan() async {
    try {
      await state.nativeWalletRepository?.rescan(topoheight: 0);
    } on AnyhowException catch (e) {
      talker.error('Rescan failed: $e');
      final xelisMessage = (e).message.split("\n")[0];
      ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
    } catch (e) {
      talker.error('Rescan failed: $e');
      final loc = ref.read(appLocalizationsProvider);
      ref.read(snackBarQueueProvider.notifier).showError(loc.oups);
    }
  }

  Future<(TransactionSummary?, String?)> send({
    required double amount,
    required String destination,
    required String asset,
    double? feeMultiplier,
  }) async {
    if (state.nativeWalletRepository != null) {
      try {
        if (state.multisigState.isSetup) {
          final transactionHash = await state.nativeWalletRepository!
              .createMultisigTransferTransaction(
                amount: amount,
                address: destination,
                assetHash: asset,
                feeMultiplier: feeMultiplier,
              );
          return (null, transactionHash);
        } else {
          final transactionSummary = await state.nativeWalletRepository!
              .createTransferTransaction(
                amount: amount,
                address: destination,
                assetHash: asset,
                feeMultiplier: feeMultiplier,
              );
          return (transactionSummary, null);
        }
      } on AnyhowException catch (e) {
        talker.error('Cannot create transaction: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return (null, null);
  }

  Future<(TransactionSummary?, String?)> sendAll({
    required String destination,
    required String asset,
    double? feeMultiplier,
  }) async {
    if (state.nativeWalletRepository != null) {
      try {
        if (state.multisigState.isSetup) {
          final transactionHash = await state.nativeWalletRepository!
              .createMultisigTransferTransaction(
                address: destination,
                assetHash: asset,
                feeMultiplier: feeMultiplier,
              );
          return (null, transactionHash);
        } else {
          final transactionSummary = await state.nativeWalletRepository!
              .createTransferTransaction(
                address: destination,
                assetHash: asset,
                feeMultiplier: feeMultiplier,
              );
          return (transactionSummary, null);
        }
      } on AnyhowException catch (e) {
        talker.error('Cannot create transaction: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return (null, null);
  }

  Future<(TransactionSummary?, String?)> burn({
    required double amount,
    required String asset,
  }) async {
    if (state.nativeWalletRepository != null) {
      try {
        if (state.multisigState.isSetup) {
          final transactionHash = await state.nativeWalletRepository!
              .createMultisigBurnTransaction(amount: amount, assetHash: asset);
          return (null, transactionHash);
        } else {
          final transactionSummary = await state.nativeWalletRepository!
              .createBurnTransaction(amount: amount, assetHash: asset);
          return (transactionSummary, null);
        }
      } on AnyhowException catch (e) {
        talker.error('Cannot create transaction: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return (null, null);
  }

  Future<(TransactionSummary?, String?)> burnAll({
    required String asset,
  }) async {
    if (state.nativeWalletRepository != null) {
      try {
        if (state.multisigState.isSetup) {
          final transactionHash = await state.nativeWalletRepository!
              .createMultisigBurnTransaction(assetHash: asset);
          return (null, transactionHash);
        } else {
          final transactionSummary = await state.nativeWalletRepository!
              .createBurnTransaction(assetHash: asset);
          return (transactionSummary, null);
        }
      } on AnyhowException catch (e) {
        talker.error('Cannot create transaction: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return (null, null);
  }

  Future<void> cancelTransaction({required String hash}) async {
    if (state.nativeWalletRepository != null) {
      await state.nativeWalletRepository!.clearTransaction(hash);
    }
  }

  Future<void> broadcastTx({required String hash}) async {
    if (state.nativeWalletRepository != null) {
      await state.nativeWalletRepository!.broadcastTransaction(hash);
    }
  }

  Future<String> estimateFees({
    required double amount,
    required String destination,
    required String asset,
    double? feeMultiplier,
  }) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.estimateFees([
        Transfer(
          floatAmount: amount,
          strAddress: destination,
          assetHash: asset,
        ),
      ], feeMultiplier);
    }
    return AppResources.zeroBalance;
  }

  Future<void> exportCsv(String path) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.exportTransactionsToCsvFile(
        '$path/genesix_transactions.csv',
      );
    }
  }

  Future<String?> exportCsvForWeb() async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.convertTransactionsToCsv();
    }
    return null;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (state.nativeWalletRepository != null) {
      await state.nativeWalletRepository!.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      // Update password in secure storage if not running in web
      if (!kIsWeb) {
        await ref
            .read(secureStorageProvider)
            .write(key: state.name, value: newPassword);
      }
    }
  }

  // Handle incoming events
  Future<void> _onEvent(Event event) async {
    final loc = ref.read(appLocalizationsProvider);
    switch (event) {
      case NewTopoHeight():
        state = state.copyWith(topoheight: event.topoheight);

      case NewTransaction():
        talker.info(event);
        ref.invalidate(historyPagingStateProvider);
        if (state.topoheight != 0 &&
            event.transactionEntry.topoheight >= state.topoheight) {
          await updateMultisigState();

          final txType = event.transactionEntry.txEntryType;

          String message;
          switch (txType) {
            case sdk.IncomingEntry():
              if (txType.isMultiTransfer()) {
                message =
                    '${loc.new_incoming_transaction.capitalize()}.\n${loc.multiple_transfers_detected.capitalize()}';
              } else {
                final atomicAmount = txType.transfers.first.amount;
                final assetHash = txType.transfers.first.asset;

                String asset;
                String amount;
                if (state.knownAssets.containsKey(assetHash)) {
                  asset = state.knownAssets[assetHash]!.name;
                  amount = formatCoin(
                    atomicAmount,
                    state.knownAssets[assetHash]!.decimals,
                    state.knownAssets[assetHash]!.ticker,
                  );
                } else {
                  asset = truncateText(assetHash);
                  amount = atomicAmount.toString();
                }

                final contactDetails = await ref
                    .read(addressBookProvider.notifier)
                    .get(txType.from);
                final from = switch (contactDetails) {
                  ContactDetails(:final name) => name,
                  null => truncateText(txType.from),
                };

                message =
                    '${loc.new_incoming_transaction.capitalize()}.\n${loc.asset}: $asset\n${loc.amount}: +$amount\n${loc.from}: $from';
              }
              ref.read(snackBarQueueProvider.notifier).showInfo(message);

            case sdk.OutgoingEntry():
              message =
                  '(#${txType.nonce}) ${loc.outgoing_transaction_confirmed.capitalize()}';
              ref.read(snackBarQueueProvider.notifier).showInfo(message);

            case sdk.CoinbaseEntry():
              final amount = formatXelis(txType.reward, state.network);
              message = '${loc.new_mining_reward.capitalize()}:\n+$amount';
              ref.read(snackBarQueueProvider.notifier).showInfo(message);

            case sdk.BurnEntry():
              String asset;
              String amount;
              if (state.knownAssets.containsKey(txType.asset)) {
                asset = state.knownAssets[txType.asset]!.name;
                amount = formatCoin(
                  txType.amount,
                  state.knownAssets[txType.asset]!.decimals,
                  state.knownAssets[txType.asset]!.ticker,
                );
              } else {
                asset = truncateText(txType.asset);
                amount = txType.amount.toString();
              }

              message =
                  '${loc.burn_transaction_confirmed.capitalize()}\n${loc.asset}: $asset\n${loc.amount}: -$amount';
              ref.read(snackBarQueueProvider.notifier).showInfo(message);

            case sdk.MultisigEntry():
              ref
                  .read(snackBarQueueProvider.notifier)
                  .showInfo(
                    '${loc.multisig_modified_successfully_event} ${event.transactionEntry.topoheight}',
                  );
            case sdk.InvokeContractEntry():
              ref
                  .read(snackBarQueueProvider.notifier)
                  .showInfo('${loc.contract_invoked} ${txType.contract}');
            case sdk.DeployContractEntry():
              ref
                  .read(snackBarQueueProvider.notifier)
                  .showInfo(
                    '${loc.contract_deployed_at} ${event.transactionEntry.topoheight}',
                  );
          }
        }

      case BalanceChanged():
        talker.info(event);
        final xelisBalance = await state.nativeWalletRepository!
            .getXelisBalance();
        final updatedBalances = await state.nativeWalletRepository!
            .getTrackedBalances();
        state = state.copyWith(
          trackedBalances: sortMapByKey(updatedBalances),
          xelisBalance: xelisBalance,
        );

      case NewAsset():
        talker.info(event);
        final assets = await state.nativeWalletRepository!.getKnownAssets();
        state = state.copyWith(knownAssets: sortMapByKey(assets));
        ref
            .read(snackBarQueueProvider.notifier)
            .showInfo(
              '${loc.new_asset_detected} ${event.rpcAssetData.name} - ${event.rpcAssetData.ticker}\n${loc.topoheight}: ${event.rpcAssetData.topoheight}',
            );

      case Rescan():
        talker.info(event);

      case Online():
        talker.info(event);
        state = state.copyWith(isOnline: true);
        ref
            .read(snackBarQueueProvider.notifier)
            .showInfo(loc.connected, duration: const Duration(seconds: 1));

      case Offline():
        talker.info(event);
        state = state.copyWith(isOnline: false);
        ref
            .read(snackBarQueueProvider.notifier)
            .showInfo(loc.disconnected, duration: const Duration(seconds: 1));

      case HistorySynced():
        talker.info(event);
      // no need to do anything here
      case SyncError():
        talker.error(event);
        ref
            .read(snackBarQueueProvider.notifier)
            .showError('${loc.error_while_syncing} ${event.message}');

      case TrackAsset():
        talker.info(event);
        final updatedBalances = await state.nativeWalletRepository!
            .getTrackedBalances();
        final assets = await state.nativeWalletRepository!.getKnownAssets();
        state = state.copyWith(
          trackedBalances: sortMapByKey(updatedBalances),
          knownAssets: sortMapByKey(assets),
        );
        ref
            .read(snackBarQueueProvider.notifier)
            .showInfo(loc.asset_successfully_tracked);

      case UntrackAsset():
        talker.info(event);
        final updatedBalances = await state.nativeWalletRepository!
            .getTrackedBalances();
        final assets = await state.nativeWalletRepository!.getKnownAssets();
        state = state.copyWith(
          trackedBalances: sortMapByKey(updatedBalances),
          knownAssets: sortMapByKey(assets),
        );
        ref
            .read(snackBarQueueProvider.notifier)
            .showInfo(loc.asset_successfully_untracked);
    }
  }

  Future<List<String>> getSeed(MnemonicLanguage language) async {
    if (state.nativeWalletRepository != null) {
      final seed = await state.nativeWalletRepository!.getSeed(
        languageIndex: language.rustIndex,
      );
      return seed.split(' ');
    }
    return [];
  }

  Future<TransactionSummary?> setupMultisig({
    required List<String> participants,
    required int threshold,
  }) async {
    if (state.nativeWalletRepository != null) {
      try {
        final transactionSummary = await state.nativeWalletRepository!
            .setupMultisig(participants: participants, threshold: threshold);
        return transactionSummary;
      } on AnyhowException catch (e) {
        talker.error('Cannot setup multisig: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot setup multisig: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return null;
  }

  bool isAddressValidForMultisig(String address) {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.isAddressValidForMultisig(address);
    }
    return false;
  }

  Future<String?> startDeleteMultisig() async {
    if (state.nativeWalletRepository != null) {
      try {
        final hash = await state.nativeWalletRepository!.initDeleteMultisig();
        return hash;
      } on AnyhowException catch (e) {
        talker.error('Cannot start delete multisig: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot start delete multisig: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return null;
  }

  Future<TransactionSummary?> finalizeMultisigTransaction({
    required List<SignatureMultisig> signatures,
  }) async {
    if (state.nativeWalletRepository != null) {
      try {
        final transactionSummary = await state.nativeWalletRepository!
            .finalizeMultisigTransaction(signatures: signatures);
        return transactionSummary;
      } on AnyhowException catch (e) {
        talker.error('Cannot finalize delete multisig: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot finalize delete multisig: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return null;
  }

  Future<void> updateMultisigState() async {
    final multisig = await state.nativeWalletRepository!.getMultisigState();
    final multisigUpdateNeeded =
        (state.multisigState.isSetup && multisig == null) ||
        (!state.multisigState.isSetup && multisig != null);
    if (multisigUpdateNeeded) {
      state = state.copyWith(multisigState: multisig ?? MultisigState());
    }
  }

  Future<String> signTransactionHash(String transactionHash) async {
    if (state.nativeWalletRepository != null) {
      try {
        final hash = await state.nativeWalletRepository!.signTransactionHash(
          transactionHash,
        );
        return hash;
      } on AnyhowException catch (e) {
        talker.error('Cannot sign transaction: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot sign transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
    return '';
  }

  Future<void> startXSWD() async {
    if (state.nativeWalletRepository != null) {
      try {
        await state.nativeWalletRepository!.startXSWD(
          cancelRequestCallback: (request) async {
            final loc = ref.read(appLocalizationsProvider);
            final message =
                '${loc.request_cancelled_from} ${request.applicationInfo.name}';
            talker.info(message);
            ref
                .read(xswdRequestProvider.notifier)
                .newRequest(xswdEventSummary: request, message: message);
          },
          requestApplicationCallback: (request) async {
            final loc = ref.read(appLocalizationsProvider);
            final message =
                '${loc.connection_request_from} ${request.applicationInfo.name}';
            talker.info(message);
            final completer = ref
                .read(xswdRequestProvider.notifier)
                .newRequest(xswdEventSummary: request, message: message);

            final decision = await completer.future;

            if (decision == UserPermissionDecision.accept ||
                decision == UserPermissionDecision.alwaysAccept) {
              ref
                  .read(snackBarQueueProvider.notifier)
                  .showInfo(
                    '${loc.permission_granted_for} ${request.applicationInfo.name}',
                  );
            } else if (decision == UserPermissionDecision.reject ||
                decision == UserPermissionDecision.alwaysReject) {
              ref
                  .read(snackBarQueueProvider.notifier)
                  .showInfo(
                    '${loc.permission_denied_for} ${request.applicationInfo.name}',
                  );
            }

            return decision;
          },
          requestPermissionCallback: (request) async {
            final loc = ref.read(appLocalizationsProvider);
            final message =
                '${loc.permission_request_from} ${request.applicationInfo.name}';
            talker.info(message);
            final completer = ref
                .read(xswdRequestProvider.notifier)
                .newRequest(xswdEventSummary: request, message: message);

            final decision = await completer.future;

            if (decision == UserPermissionDecision.accept ||
                decision == UserPermissionDecision.alwaysAccept) {
              ref
                  .read(snackBarQueueProvider.notifier)
                  .showInfo(
                    '${loc.permission_granted_for} ${request.applicationInfo.name}',
                  );
            } else if (decision == UserPermissionDecision.reject ||
                decision == UserPermissionDecision.alwaysReject) {
              ref
                  .read(snackBarQueueProvider.notifier)
                  .showInfo(
                    '${loc.permission_denied_for} ${request.applicationInfo.name}',
                  );
            }

            return decision;
          },
          appDisconnectCallback: (request) async {
            final loc = ref.read(appLocalizationsProvider);
            final message =
                'XSWD: ${request.applicationInfo.name} ${loc.disconnected.toLowerCase()}';
            talker.info(message);
            ref
                .read(xswdRequestProvider.notifier)
                .newRequest(xswdEventSummary: request, message: message);
          },
        );
      } on AnyhowException catch (e) {
        talker.error('Cannot start XSWD: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot start XSWD: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
  }

  Future<void> stopXSWD() async {
    if (state.nativeWalletRepository != null) {
      try {
        await state.nativeWalletRepository!.stopXSWD();
      } on AnyhowException catch (e) {
        talker.error('Cannot stop XSWD: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot stop XSWD: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
  }

  Future<void> closeXswdAppConnection(AppInfo appInfo) async {
    if (state.nativeWalletRepository != null) {
      final loc = ref.read(appLocalizationsProvider);
      try {
        await state.nativeWalletRepository!.removeXswdApp(appInfo.id);
        ref
            .read(snackBarQueueProvider.notifier)
            .showInfo(
              'XSWD: ${appInfo.name} ${loc.disconnected.toLowerCase()}',
            );
      } on AnyhowException catch (e) {
        talker.error('Cannot close XSWD app connection: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot close XSWD app connection: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
  }

  Future<void> editXswdAppPermission(
    String appID,
    Map<String, PermissionPolicy> permissions,
  ) async {
    if (state.nativeWalletRepository != null) {
      try {
        await state.nativeWalletRepository!.modifyXSWDAppPermissions(
          appID,
          permissions,
        );
      } on AnyhowException catch (e) {
        talker.error('Cannot edit XSWD app permission: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot edit XSWD app permission: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
  }

  Future<void> trackAsset(String assetHash) async {
    if (state.nativeWalletRepository != null) {
      try {
        await state.nativeWalletRepository!.trackAsset(assetHash);
      } on AnyhowException catch (e) {
        talker.error('Cannot track asset: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot track asset: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
  }

  Future<void> untrackAsset(String assetHash) async {
    if (state.nativeWalletRepository != null) {
      try {
        await state.nativeWalletRepository!.untrackAsset(assetHash);
      } on AnyhowException catch (e) {
        talker.error('Cannot untrack asset: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarQueueProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot untrack asset: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackBarQueueProvider.notifier).showError('${loc.oups}\n$e');
      }
    }
  }
}

// utility extension for TransactionEntryType
extension TransactionUtils on sdk.TransactionEntryType {
  bool isMultiTransfer() {
    if (this is sdk.IncomingEntry) {
      return (this as sdk.IncomingEntry).transfers.length > 1;
    } else if (this is sdk.OutgoingEntry) {
      return (this as sdk.OutgoingEntry).transfers.length > 1;
    } else {
      return false;
    }
  }
}
