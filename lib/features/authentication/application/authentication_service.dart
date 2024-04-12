import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/wallets_state_provider.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/router/router.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/authentication_state.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/native_wallet_repository.dart';
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
    final precomputedTablesPath = await _getPrecomputedTablesPath();
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
              walletPath, password, settings.network,
              seed: seed, precomputeTablesPath: precomputedTablesPath);
        } else {
          walletRepository = await NativeWalletRepository.create(
              walletPath, password, settings.network,
              precomputeTablesPath: precomputedTablesPath);
        }
      } catch (e) {
        logger.severe('Creating wallet failed: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(
                message: loc.wallet_creation_failed_toast_error));
        rethrow;
      }

      //ref
      //   .read(networkWalletProvider.notifier)
      //  .setWallet(settings.network, name, walletRepository.address);

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      ref.read(routerProvider).go(AppScreen.wallet.toPath);

      state = AuthenticationState.signedIn(
          name: name, nativeWallet: walletRepository);

      ref.read(walletStateProvider.notifier).connect();
    }
  }

  Future<void> openWallet(String name, String password) async {
    final settings = ref.read(settingsProvider);
    final precomputedTablesPath = await _getPrecomputedTablesPath();

    var walletPath = await getWalletPath(settings.network, name);
    var walletExists = await Directory(walletPath).exists();

    if (walletExists) {
      NativeWalletRepository walletRepository;
      try {
        walletRepository = await NativeWalletRepository.open(
            walletPath, password, settings.network,
            precomputeTablesPath: precomputedTablesPath);
      } catch (e) {
        logger.severe('Opening wallet failed: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(
                message: loc.wallet_opening_failed_toast_error));
        rethrow;
      }

      // ref
      //    .read(networkWalletProvider.notifier)
      //    .setWallet(settings.network, name, walletRepository.address);

      ref
          .read(walletsProvider.notifier)
          .setWalletAddress(name, walletRepository.address);

      state = AuthenticationState.signedIn(
          name: name, nativeWallet: walletRepository);

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

  Future<String> _getPrecomputedTablesPath() async {
    final dir = await getApplicationCacheDirectory();
    return "${dir.path}/";
  }

  Future<bool> isPrecomputedTablesExists() async {
    return precomputedTablesExist(
        precomputedTablesPath: await _getPrecomputedTablesPath());
  }
}
