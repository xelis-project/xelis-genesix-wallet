import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/router/route_utils.dart';
import 'package:xelis_mobile_wallet/router/router.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/network_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/authentication/domain/authentication_state.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/data/native_wallet_repository.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';

part 'authentication_service.g.dart';

@riverpod
class Authentication extends _$Authentication {
  @override
  AuthenticationState build() {
    return const AuthenticationState.signedOut();
  }

  Future<void> createWallet(
    String name,
    String password, [
    String? seed,
  ]) async {
    final settings = ref.read(settingsProvider);

    var walletPath = await getWalletPath(settings.network, name);
    var walletExists = await Directory(walletPath).exists();

    if (walletExists) {
      logger.severe('This wallet already exists: $name');
      throw Exception('This wallet already exists: $name');
    } else {
      NativeWalletRepository walletRepository;

      try {
        if (seed != null) {
          walletRepository = await NativeWalletRepository.recover(
            walletPath,
            password,
            settings.network,
            seed: seed,
          );
        } else {
          walletRepository = await NativeWalletRepository.create(
              walletPath, password, Network.testnet);
        }
      } catch (e) {
        logger.severe('Creating wallet failed: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(
                message: loc.wallet_creation_failed_toast_error));
        rethrow;
      }

      ref
          .read(networkWalletProvider.notifier)
          .setWallet(settings.network, name, walletRepository.address);

      ref.read(routerProvider).go(AppScreen.wallet.toPath);

      state = AuthenticationState.signedIn(nativeWallet: walletRepository);

      ref.read(walletStateProvider.notifier).connect();
    }
  }

  Future<void> openWallet(String name, String password) async {
    final settings = ref.read(settingsProvider);

    var walletPath = await getWalletPath(settings.network, name);
    var walletExists = await Directory(walletPath).exists();

    if (walletExists) {
      NativeWalletRepository walletRepository;
      try {
        walletRepository = await NativeWalletRepository.open(
          walletPath,
          password,
          settings.network,
        );
      } catch (e) {
        logger.severe('Opening wallet failed: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(
                message: loc.wallet_opening_failed_toast_error));
        rethrow;
      }

      ref
          .read(networkWalletProvider.notifier)
          .setWallet(settings.network, name, walletRepository.address);

      state = AuthenticationState.signedIn(nativeWallet: walletRepository);

      ref.read(routerProvider).go(AppScreen.wallet.toPath);

      ref.read(walletStateProvider.notifier).connect();
    } else {
      logger.severe('This wallet does not exist: $name');
      throw Exception('This wallet does not exist: $name');
    }
  }

  Future<void> logout() async {
    switch (state) {
      case SignedIn(:final nativeWallet):
        await ref.read(walletStateProvider.notifier).disconnect();
        nativeWallet.dispose();
        state = const AuthenticationState.signedOut();

        ref.read(routerProvider).go(AppScreen.openWallet.toPath);

      case SignedOut():
        return;
    }
  }
}
