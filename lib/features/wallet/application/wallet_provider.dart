import 'dart:async';

import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';
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
      StreamSubscription<void> sub =
          state.nativeWalletRepository!.convertRawEvents().listen(_onEvent);
      state = state.copyWith(streamSubscription: sub);

      if (await state.nativeWalletRepository!.isOnline) {
        await disconnect();
      }

      final settings = ref.read(settingsProvider);
      final networkNodes = ref.read(networkNodesProvider);
      var node = networkNodes.getNodeAddress(settings.network);

      await state.nativeWalletRepository!
          .setOnline(daemonAddress: node.url)
          .onError((error, stackTrace) {
        final loc = ref.read(appLocalizationsProvider);
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.cannot_connect_toast_error);
      });

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
    final loc = ref.read(appLocalizationsProvider);
    try {
      final nodeInfo = await state.nativeWalletRepository?.getDaemonInfo();
      if (nodeInfo?.prunedTopoHeight == null) {
        // We are connected to a full node, so we can rescan from 0.
        await state.nativeWalletRepository?.rescan(topoHeight: 0);
        ref.read(snackBarMessengerProvider.notifier).showInfo(loc.rescan_done);
      } else {
        // We are connected to a pruned node, rescan is not available for simplicity.
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.rescan_limitation_toast_error);
      }
    } catch (e) {
      final loc = ref.read(appLocalizationsProvider);
      ref.read(snackBarMessengerProvider.notifier).showError(loc.oups);
    }
  }

  Future<TransactionSummary?> createXelisTransaction({
    required double amount,
    required String destination,
    required String asset,
  }) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.createSimpleTransferTransaction(
          amount: amount, address: destination, assetHash: asset);
    }
    return null;
  }

  Future<TransactionSummary?> createAllXelisTransaction({
    required String destination,
    required String asset,
  }) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.createSimpleTransferTransaction(
          address: destination, assetHash: asset);
    }
    return null;
  }

  Future<TransactionSummary?> createBurnTransaction(
      {required double amount, required String asset}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .createBurnTransaction(amount: amount, assetHash: asset);
    }
    return null;
  }

  Future<TransactionSummary?> createBurnAllTransaction(
      {required String asset}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .createBurnTransaction(assetHash: asset);
    }
    return null;
  }

  Future<TransactionSummary?> createBurnXelisTransaction(
      {required double amount}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .createBurnTransaction(amount: amount, assetHash: sdk.xelisAsset);
    }
    return null;
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
  }) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.estimateFees([
        Transfer(floatAmount: amount, strAddress: destination, assetHash: asset)
      ]);
    }
    return AppResources.zeroBalance;
  }

  Future<void> exportCsv(String path) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .exportTransactionsToCsvFile('$path/genesix_transactions.csv');
    }
  }

  Future<String?> exportCsvForWeb() async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.convertTransactionsToCsv();
    }
    return null;
  }

  // Handle incoming events
  Future<void> _onEvent(Event event) async {
    final loc = ref.read(appLocalizationsProvider);
    switch (event) {
      case NewTopoHeight():
        state = state.copyWith(topoheight: event.topoHeight);

      case NewTransaction():
        talker.info(event);
        if (state.topoheight != 0 &&
            event.transactionEntry.topoHeight >= state.topoheight) {
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
                final amount = await state.nativeWalletRepository!
                    .formatCoin(atomicAmount, assetHash);
                final asset = assetHash == sdk.xelisAsset
                    ? 'XELIS'
                    : truncateText(assetHash);
                message =
                    '${loc.new_incoming_transaction.capitalize()}.\n${loc.asset}: $asset\n${loc.amount}: +$amount';
              }

              ref.read(snackBarMessengerProvider.notifier).showInfo(message);

            case sdk.OutgoingEntry():
              ref.read(snackBarMessengerProvider.notifier).showInfo(
                  '(#${txType.nonce}) ${loc.outgoing_transaction_confirmed.capitalize()}');

            case sdk.CoinbaseEntry():
              final amount = await state.nativeWalletRepository!
                  .formatCoin(txType.reward, sdk.xelisAsset);
              ref.read(snackBarMessengerProvider.notifier).showInfo(
                  '${loc.new_mining_reward.capitalize()}:\n+$amount XEL');

            case sdk.BurnEntry():
              final amount = await state.nativeWalletRepository!
                  .formatCoin(txType.amount, txType.asset);
              final asset = txType.asset == sdk.xelisAsset
                  ? 'XELIS'
                  : truncateText(txType.asset);
              ref.read(snackBarMessengerProvider.notifier).showInfo(
                  '${loc.burn_transaction_confirmed.capitalize()}\n${loc.asset}: $asset\n${loc.amount}: -$amount');
          }

          // Temporary workaround to update XELIS balance on new outgoing transaction.
          // Normally there should be a BalanceChanged event for this case ...
          state = state.copyWith(
            xelisBalance: await state.nativeWalletRepository!.getXelisBalance(),
          );
        }

      case BalanceChanged():
        talker.info(event);
        final asset = event.balanceChanged.assetHash;
        final newBalance = await state.nativeWalletRepository!
            .formatCoin(event.balanceChanged.balance, asset);
        final updatedAssets = Map<String, String>.from(state.assets);
        updatedAssets[event.balanceChanged.assetHash] = newBalance;

        if (event.balanceChanged.assetHash == sdk.xelisAsset) {
          final xelisBalance =
              await state.nativeWalletRepository!.getXelisBalance();
          state =
              state.copyWith(assets: updatedAssets, xelisBalance: xelisBalance);
        } else {
          state = state.copyWith(assets: updatedAssets);
        }

      case NewAsset():
        talker.info(event);

      case Rescan():
        talker.info(event);

      case Online():
        talker.info(event);
        state = state.copyWith(isOnline: true);

      case Offline():
        talker.info(event);
        state = state.copyWith(isOnline: false);
    }
  }

  Future<List<String>> getSeed(MnemonicLanguage language) async {
    if (state.nativeWalletRepository != null) {
      final seed = await state.nativeWalletRepository!
          .getSeed(languageIndex: language.rustIndex);
      return seed.split(' ');
    }
    return [];
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
