import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/domain/authentication_state.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/domain/event.dart';
import 'package:genesix/features/wallet/domain/native_transaction.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/features/wallet/domain/wallet_snapshot.dart';
import 'package:genesix/shared/logger.dart';
import 'package:genesix/shared/providers/snackbar_content_provider.dart';
import 'package:genesix/shared/providers/snackbar_event.dart';
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
            address: state.nativeWalletRepository!.address, nonce: nonce);
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
        ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(message: loc.cannot_connect_toast_error));
      });

      if (await state.nativeWalletRepository!.isOnline) {
        if (await state.nativeWalletRepository!.hasXelisBalance()) {
          final xelisBalance =
              await state.nativeWalletRepository!.getXelisBalance();
          state = state.copyWith(xelisBalance: xelisBalance);
        } else {
          state = state.copyWith(xelisBalance: formatXelis(0));
        }
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
    var nodeInfo = await state.nativeWalletRepository?.getDaemonInfo();
    final loc = ref.read(appLocalizationsProvider);
    if (nodeInfo?.prunedTopoHeight == null) {
      // We are connected to a full node, so we can rescan from 0.
      await state.nativeWalletRepository?.rescan(topoHeight: 0);
      ref
          .read(snackbarContentProvider.notifier)
          .setContent(SnackbarEvent.info(message: loc.rescan_done));
    } else {
      // We are connected to a pruned node, rescan is not available.
      ref.read(snackbarContentProvider.notifier).setContent(
          SnackbarEvent.error(message: loc.rescan_limitation_toast_error));
    }
  }

  Future<NativeTransaction?> createXelisTransaction(
      {required double amount, required String destination}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .createSimpleTransaction(amount: amount, address: destination);
    }
    return null;
  }

  Future<NativeTransaction?> createBurnXelisTransaction(
      {required double amount}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .createBurnTransaction(amount: amount, assetHash: xelisAsset);
    }
    return null;
  }

  Future<void> broadcastTx({required NativeTransaction tx}) async {
    if (state.nativeWalletRepository != null) {
      await state.nativeWalletRepository!.broadcastTransaction(tx);
    }
  }

  Future<void> _onEvent(Event event) async {
    switch (event) {
      case NewTopoHeight():
        state = state.copyWith(topoheight: event.topoHeight);

      case NewTransaction():
        logger.info(event);
        if (state.topoheight != 0 &&
            event.transactionEntry.topoHeight >= state.topoheight) {
          final loc = ref.read(appLocalizationsProvider);
          ref.read(snackbarContentProvider.notifier).setContent(SnackbarEvent.info(
              message:
                  '${loc.new_transaction_toast_info} ${event.transactionEntry}'));
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

        if (event.balanceChanged.assetHash == xelisAsset) {
          final xelisBalance =
              await state.nativeWalletRepository!.getXelisBalance();
          state = state.copyWith(
              nonce: nonce, assets: updatedAssets, xelisBalance: xelisBalance);
        } else {
          state = state.copyWith(nonce: nonce, assets: updatedAssets);
        }

      case NewAsset():
        logger.info(event);

      case Rescan():
        logger.info(event);

      case Online():
        state = state.copyWith(isOnline: true);

      case Offline():
        state = state.copyWith(isOnline: false);
    }
  }
}
