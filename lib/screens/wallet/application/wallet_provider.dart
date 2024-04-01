import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/network_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/authentication/domain/authentication_state.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/node_addresses_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/history_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/domain/event.dart';
import 'package:xelis_mobile_wallet/screens/wallet/domain/node_address.dart';
import 'package:xelis_mobile_wallet/screens/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';

part 'wallet_provider.g.dart';

@riverpod
class WalletState extends _$WalletState {
  @override
  WalletSnapshot build() {
    final authenticationState = ref.watch(authenticationProvider);
    final networkWallet = ref.watch(networkWalletProvider);
    final settings = ref.watch(settingsProvider);
    var name = networkWallet.getOpenWallet(settings.network);

    switch (authenticationState) {
      case SignedIn(:final nativeWallet):
        return WalletSnapshot(
            name: name ?? '', nativeWalletRepository: nativeWallet);
      case SignedOut():
        return WalletSnapshot(name: name ?? '');
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

      final address = ref.read(nodeAddressesProvider);
      await state.nativeWalletRepository!
          .setOnline(daemonAddress: address.favorite.url)
          .onError((error, stackTrace) {
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(message: loc.cannot_connect_toast_error));
      });

      if (await state.nativeWalletRepository!.isOnline) {
        final xelisBalance =
            await state.nativeWalletRepository!.getXelisBalance();
        state = state.copyWith(xelisBalance: xelisBalance);
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
      ref.read(nodeAddressesProvider.notifier).setFavoriteAddress(nodeAddress);
    }
    await disconnect();
    unawaited(connect());
  }

  Future<void> rescan() async {
    var nodeInfo = await state.nativeWalletRepository?.getDaemonInfo();
    final loc = ref.read(appLocalizationsProvider);
    if (nodeInfo?.prunedTopoHeight == null) {
      await state.nativeWalletRepository?.rescan(topoHeight: 0);
      ref
          .read(snackbarContentProvider.notifier)
          .setContent(SnackbarEvent.info(message: loc.rescan_done));
    } else {
      ref.read(snackbarContentProvider.notifier).setContent(
          SnackbarEvent.error(message: loc.rescan_limitation_toast_error));
    }
  }

  Future<String?> getSeed(String password) async {
    return state.nativeWalletRepository?.getSeed(password: password);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await state.nativeWalletRepository
          ?.changePassword(oldPassword: oldPassword, newPassword: newPassword);
    } catch (e) {
      logger.severe('Changing password failed: $e');
      final loc = ref.read(appLocalizationsProvider);
      ref.read(snackbarContentProvider.notifier).setContent(
          SnackbarEvent.error(message: loc.password_cannot_be_changed_error));
      rethrow;
    }
  }

  Future<String?> send(
      {required double amount,
      required String address,
      String? assetHash}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .transfer(amount: amount, address: address);
    }
    final loc = ref.read(appLocalizationsProvider);
    ref
        .read(snackbarContentProvider.notifier)
        .setContent(SnackbarEvent.error(message: loc.transfer_failed));
    return null;
  }

  Future<void> _onEvent(Event event) async {
    switch (event) {
      case NewTopoHeight():
        state = state.copyWith(topoheight: event.topoHeight);

      case NewTransaction():
        logger.info(event);
        ref.invalidate(historyProvider);
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
