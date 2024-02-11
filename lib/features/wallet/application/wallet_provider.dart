import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/open_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/authentication_state.dart';
import 'package:xelis_mobile_wallet/features/settings/application/node_addresses_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/event.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/node_address.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

part 'wallet_provider.g.dart';

@riverpod
class WalletState extends _$WalletState {
  @override
  WalletSnapshot build() {
    final authenticationState = ref.watch(authenticationProvider);
    final name = ref
        .watch(openWalletProvider.select((value) => value.walletCurrentlyUsed));

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
        state = state.copyWith(
            address: state.nativeWalletRepository!.humanReadableAddress);
      }

      state.nativeWalletRepository!.convertRawEvents().listen((event) async {
        switch (event) {
          case NewTopoHeight():
            state = state.copyWith(topoheight: event.topoHeight);

          case NewTransaction():
            logger.info(event);
          // final nonce = await state.nativeWalletRepository!.nonce;
          // state = state.copyWith(nonce: nonce);
          // TODO: Handle with toast

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
                  nonce: nonce,
                  assets: updatedAssets,
                  xelisBalance: xelisBalance);
            } else {
              state = state.copyWith(nonce: nonce, assets: updatedAssets);
            }

          case NewAsset():
            logger.info(event);
          // TODO: Handle this case.

          case Rescan():
            logger.info(event);
          // TODO: Handle this case.

          case Online():
            state = state.copyWith(isOnline: true);

          case Offline():
            state = state.copyWith(isOnline: false);
        }
      });

      if (await state.nativeWalletRepository!.isOnline) {
        await state.nativeWalletRepository!.setOffline();
      }

      final address = ref.read(nodeAddressesProvider);
      await state.nativeWalletRepository!
          .setOnline(daemonAddress: address.favorite.url);

      if (await state.nativeWalletRepository!.isOnline) {
        final xelisBalance =
            await state.nativeWalletRepository!.getXelisBalance();
        state = state.copyWith(xelisBalance: xelisBalance);

        state.nativeWalletRepository!.getDaemonInfo().listen((daemonInfoEvent) {
          final newState = state.copyWith(
              daemonInfo: state.daemonInfo.copyWith(
                  height: daemonInfoEvent.height,
                  topoHeight: daemonInfoEvent.topoHeight,
                  pruned:
                      daemonInfoEvent.prunedTopoHeight != null ? true : false,
                  circulatingSupply: daemonInfoEvent.circulatingSupply,
                  mempoolSize: daemonInfoEvent.mempoolSize,
                  version: daemonInfoEvent.version,
                  network: daemonInfoEvent.network));
          if (state != newState) {
            state = newState;
          }
        });
      }
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(isOnline: false);
    await state.nativeWalletRepository?.setOffline();
    await state.nativeWalletRepository?.close();
  }

  Future<void> reconnect(NodeAddress nodeAddress) async {
    ref.read(nodeAddressesProvider.notifier).setFavoriteAddress(nodeAddress);
    await disconnect();
    unawaited(connect());
  }

  Future<String?> send(
      {required double amount,
      required String address,
      String? assetHash}) async {
    if (state.nativeWalletRepository != null) {
      return state.nativeWalletRepository!
          .transfer(amount: amount, address: address);
    } else {
      // TODO throw error for toast system
    }
    return null;
  }
}
