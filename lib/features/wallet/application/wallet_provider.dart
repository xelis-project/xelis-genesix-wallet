import 'dart:async';

import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
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
import 'package:genesix/shared/logger.dart';
import 'package:genesix/shared/utils/utils.dart';

part 'wallet_provider.g.dart';

@riverpod
class WalletState extends _$WalletState {
  @override
  WalletSnapshot build() {
    final authenticationState = ref.watch(authenticationProvider);

    switch (authenticationState) {
      case SignedIn(:final name, :final nativeWallet):
        return WalletSnapshot(name: name, nativeWalletRepository: nativeWallet);
      case SignedOut():
        return const WalletSnapshot();
    }
  }

  Future<void> connect() async {
    if (state.nativeWalletRepository != null) {
      if (state.address.isEmpty) {
        final nonce = await state.nativeWalletRepository!.nonce;
        state = state.copyWith(
            address: state.nativeWalletRepository!.address,
            nonce: nonce.toInt());
      }

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

      if (await state.nativeWalletRepository!.hasXelisBalance()) {
        final xelisBalance =
            await state.nativeWalletRepository!.getXelisBalance();
        state = state.copyWith(xelisBalance: xelisBalance);
      } else {
        state = state.copyWith(xelisBalance: formatXelis(0));
      }
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(isOnline: false);

    try {
      await state.nativeWalletRepository?.setOffline();
    } catch (e) {
      logger.warning('Something went wrong when disconnecting...');
    }

    try {
      await state.nativeWalletRepository?.close();
    } catch (e) {
      logger.warning('Something went wrong when closing wallet...');
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
        // We are connected to a pruned node, rescan is not available.
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.rescan_limitation_toast_error);
      }
    } catch (e) {
      final loc = ref.read(appLocalizationsProvider);
      ref.read(snackBarMessengerProvider.notifier).showError(loc.oups);
    }
  }

  Future<TransactionSummary?> createXelisTransaction(
      {required double amount, required String destination}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.createSimpleTransferTransaction(
          amount: amount, address: destination);
    }
    return null;
  }

  Future<TransactionSummary?> createAllXelisTransaction(
      {required String destination}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .createSimpleTransferTransaction(address: destination);
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

  // TODO rework
  Future<BigInt> estimateFees(
      {required double amount, required String destination}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!.estimateFees(
          [Transfer(floatAmount: amount, strAddress: destination)]);
    }
    return BigInt.zero;
  }

  Future<void> _onEvent(Event event) async {
    final loc = ref.read(appLocalizationsProvider);
    switch (event) {
      case NewTopoHeight():
        state = state.copyWith(topoheight: event.topoHeight);

      case NewTransaction():
        logger.info(event);
        if (state.topoheight != 0 &&
            event.transactionEntry.topoHeight >= state.topoheight) {
          ref.read(snackBarMessengerProvider.notifier).showInfo(
              '${loc.new_transaction_toast_info} ${event.transactionEntry}');

          // Temporary workaround to update XELIS balance on new outgoing transaction.
          // Normally there should be a BalanceChanged event for this case ...
          if (await state.nativeWalletRepository?.hasXelisBalance() ?? false) {
            state = state.copyWith(
                xelisBalance:
                    await state.nativeWalletRepository!.getXelisBalance());
          }
        }

      case BalanceChanged():
        logger.info(event);
        final nonce = await state.nativeWalletRepository!.nonce;

        var updatedAssets = <String, int>{};
        if (state.assets == null) {
          updatedAssets = {
            event.balanceChanged.assetHash: event.balanceChanged.balance
          };
        } else {
          final updatedAssets = Map<String, int>.from(state.assets!);
          updatedAssets[event.balanceChanged.assetHash] =
              event.balanceChanged.balance;
        }

        if (event.balanceChanged.assetHash == sdk.xelisAsset) {
          final xelisBalance =
              await state.nativeWalletRepository!.getXelisBalance();
          state = state.copyWith(
              nonce: nonce.toInt(),
              assets: updatedAssets,
              xelisBalance: xelisBalance);
        } else {
          state = state.copyWith(nonce: nonce.toInt(), assets: updatedAssets);
        }

      case NewAsset():
        logger.info(event);

      case Rescan():
        logger.info(event);

      case Online():
        logger.info(event);
        state = state.copyWith(isOnline: true);
      // ref.read(snackBarMessengerProvider.notifier).showInfo(loc.connected);

      case Offline():
        logger.info(event);
        state = state.copyWith(isOnline: false);
      // ref.read(snackBarMessengerProvider.notifier).showInfo(loc.disconnected);
    }
  }
}
