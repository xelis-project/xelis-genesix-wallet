import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:flutter/foundation.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
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
        );
      case SignedOut():
        return const WalletSnapshot();
    }
  }

  Future<void> connect() async {
    if (state.nativeWalletRepository != null) {
      final loc = ref.read(appLocalizationsProvider);

      if (await state.nativeWalletRepository!.isOnline) {
        await disconnect();
      }

      StreamSubscription<void> sub =
      state.nativeWalletRepository!.convertRawEvents().listen(_onEvent);
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
            .read(snackBarMessengerProvider.notifier)
            .showError(
              '${loc.cannot_connect_toast_error.replaceFirst(RegExp(r'\.'), ':')}\n$xelisMessage',
            );
      } catch (e) {
        talker.warning('Cannot connect to node: $e');
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(
              '${loc.cannot_connect_toast_error.replaceFirst(RegExp(r'\.'), ':')}\n$e',
            );
      }

      final multisig = await state.nativeWalletRepository!.getMultisigState();
      if (multisig != null) state = state.copyWith(multisigState: multisig);

      final xelisBalance =
          await state.nativeWalletRepository!.getXelisBalance();
      final assets = await state.nativeWalletRepository!.getAssetBalances();

      if (assets.isNotEmpty) {
        state = state.copyWith(xelisBalance: xelisBalance, assets: assets);
      } else {
        state = state.copyWith(xelisBalance: xelisBalance);
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

  Future<void> reconnect([NodeAddress? nodeAddress]) async {
    if (nodeAddress != null) {
      final settings = ref.read(settingsProvider);
      ref
          .read(networkNodesProvider.notifier)
          .setNodeAddress(settings.network, nodeAddress);
    }
    await disconnect();
    unawaited(connect());
  }

  Future<void> rescan() async {
    try {
      await state.nativeWalletRepository?.rescan(topoheight: 0);
    } on AnyhowException catch (e) {
      talker.error('Rescan failed: $e');
      final xelisMessage = (e).message.split("\n")[0];
      ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
    } catch (e) {
      talker.error('Rescan failed: $e');
      final loc = ref.read(appLocalizationsProvider);
      ref.read(snackBarMessengerProvider.notifier).showError(loc.oups);
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
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
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
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
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
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
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
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot create transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
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
        if (state.topoheight != 0 &&
            event.transactionEntry.topoheight >= state.topoheight) {
          await updateMultisigState();

          final txType = event.transactionEntry.txEntryType;

          switch (txType) {
            case sdk.IncomingEntry():
              String message;
              if (txType.isMultiTransfer()) {
                message =
                    '${loc.new_incoming_transaction.capitalize()}.\n${loc.multiple_transfers_detected.capitalize()}';
              } else {
                final atomicAmount = txType.transfers.first.amount;
                final assetHash = txType.transfers.first.asset;
                final amount = await state.nativeWalletRepository!.formatCoin(
                  atomicAmount,
                  assetHash,
                );
                final asset =
                    assetHash == sdk.xelisAsset
                        ? AppResources.xelisAsset.name
                        : truncateText(assetHash);
                message =
                    '${loc.new_incoming_transaction.capitalize()}.\n${loc.asset}: $asset\n${loc.amount}: +$amount';
              }

              ref.read(snackBarMessengerProvider.notifier).showInfo(message);

            case sdk.OutgoingEntry():
              ref
                  .read(snackBarMessengerProvider.notifier)
                  .showInfo(
                    '(#${txType.nonce}) ${loc.outgoing_transaction_confirmed.capitalize()}',
                  );

            case sdk.CoinbaseEntry():
              final amount = await state.nativeWalletRepository!.formatCoin(
                txType.reward,
                sdk.xelisAsset,
              );
              ref
                  .read(snackBarMessengerProvider.notifier)
                  .showInfo(
                    '${loc.new_mining_reward.capitalize()}:\n+$amount ${AppResources.xelisAsset.ticker}',
                  );

            case sdk.BurnEntry():
              final amount = await state.nativeWalletRepository!.formatCoin(
                txType.amount,
                txType.asset,
              );
              final asset =
                  txType.asset == sdk.xelisAsset
                      ? AppResources.xelisAsset.name
                      : truncateText(txType.asset);
              ref
                  .read(snackBarMessengerProvider.notifier)
                  .showInfo(
                    '${loc.burn_transaction_confirmed.capitalize()}\n${loc.asset}: $asset\n${loc.amount}: -$amount',
                  );
            case sdk.MultisigEntry():
              ref
                  .read(snackBarMessengerProvider.notifier)
                  .showInfo(
                    '${loc.multisig_modified_successfully_event} ${event.transactionEntry.topoheight}',
                  );
            case sdk.InvokeContractEntry():
              // TODO: Handle this case.
              throw UnimplementedError();
            case sdk.DeployContractEntry():
              // TODO: Handle this case.
              throw UnimplementedError();
          }
        }

      case BalanceChanged():
        talker.info(event);
        final asset = event.balanceChanged.assetHash;
        final newBalance = await state.nativeWalletRepository!.formatCoin(
          event.balanceChanged.balance,
          asset,
        );
        final updatedAssets = Map<String, String>.from(state.assets);
        updatedAssets[event.balanceChanged.assetHash] = newBalance;

        if (event.balanceChanged.assetHash == sdk.xelisAsset) {
          final xelisBalance =
              await state.nativeWalletRepository!.getXelisBalance();
          state = state.copyWith(
            assets: updatedAssets,
            xelisBalance: xelisBalance,
          );
        } else {
          state = state.copyWith(assets: updatedAssets);
        }

      case NewAsset():
        talker.info(event);
      // TODO: Handle this case.

      case Rescan():
        talker.info(event);

      case Online():
        talker.info(event);
        state = state.copyWith(isOnline: true);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showInfo(loc.connected, durationInSeconds: 1);

      case Offline():
        talker.info(event);
        state = state.copyWith(isOnline: false);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showInfo(loc.disconnected, durationInSeconds: 1);

      case HistorySynced():
        talker.info(event);
      // no need to do anything
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
        return state.nativeWalletRepository!.setupMultisig(
          participants: participants,
          threshold: threshold,
        );
      } on AnyhowException catch (e) {
        talker.error('Cannot setup multisig: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot setup multisig: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
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
        return state.nativeWalletRepository!.initDeleteMultisig();
      } on AnyhowException catch (e) {
        talker.error('Cannot start delete multisig: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot start delete multisig: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
      }
    }
    return null;
  }

  Future<TransactionSummary?> finalizeDeleteMultisig({
    required List<SignatureMultisig> signatures,
  }) async {
    if (state.nativeWalletRepository != null) {
      try {
        return state.nativeWalletRepository!.finalizeMultisigTransaction(
          signatures: signatures,
        );
      } on AnyhowException catch (e) {
        talker.error('Cannot finalize delete multisig: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot finalize delete multisig: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
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
        return state.nativeWalletRepository!.signTransactionHash(
          transactionHash,
        );
      } on AnyhowException catch (e) {
        talker.error('Cannot sign transaction: $e');
        final xelisMessage = (e).message.split("\n")[0];
        ref.read(snackBarMessengerProvider.notifier).showError(xelisMessage);
      } catch (e) {
        talker.error('Cannot sign transaction: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError('${loc.oups}\n$e');
      }
    }
    return '';
  }
}

// utility extension for TransactionEntryType
// TODO move to xelis_dart_sdk
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
