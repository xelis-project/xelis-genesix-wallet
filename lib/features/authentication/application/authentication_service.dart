import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/open_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/authentication_state.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/src/rust/api/wallet.dart';

part 'authentication_service.g.dart';

@riverpod
class Authentication extends _$Authentication {
  final String _userFolderName = 'XELIS wallets';

  @override
  AuthenticationState build() {
    return const AuthenticationState.signedOut();
  }

  Future<void> createWallet(
    String name,
    String password, [
    String? seed,
  ]) async {
    final walletPath = await _getWalletPath(name);
    final precomputedTablesPath = await _getPrecomputedTablesPath();

    if (await Directory(walletPath).exists()) {
      logger.severe('This wallet already exists: $name');
      throw Exception('This wallet already exists: $name');
    } else {
      NativeWalletRepository walletRepository;

      try {
        if (seed != null) {
          walletRepository = await NativeWalletRepository.recover(
              walletPath, password, Network.testnet,
              seed: seed, precomputeTablesPath: precomputedTablesPath);
        } else {
          walletRepository = await NativeWalletRepository.create(
              walletPath, password, Network.testnet,
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

      ref.read(openWalletProvider.notifier).saveOpenWalletState(name,
          address: walletRepository.humanReadableAddress);

      state = AuthenticationState.signedIn(nativeWallet: walletRepository);

      ref.read(walletStateProvider.notifier).connect();
    }
  }

  Future<void> openWallet(String name, String password) async {
    final walletPath = await _getWalletPath(name);
    final precomputedTablesPath = await _getPrecomputedTablesPath();

    if (await Directory(walletPath).exists()) {
      NativeWalletRepository walletRepository;
      try {
        walletRepository = await NativeWalletRepository.open(
            walletPath, password, Network.testnet,
            precomputeTablesPath: precomputedTablesPath);
      } catch (e) {
        logger.severe('Opening wallet failed: $e');
        final loc = ref.read(appLocalizationsProvider);
        ref.read(snackbarContentProvider.notifier).setContent(
            SnackbarEvent.error(
                message: loc.wallet_opening_failed_toast_error));
        rethrow;
      }

      ref.read(openWalletProvider.notifier).saveOpenWalletState(name);

      state = AuthenticationState.signedIn(nativeWallet: walletRepository);

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
      case SignedOut():
        return;
    }
  }

  Future<bool> isPrecomputedTablesExists() async {
    return precomputedTablesExist(
        precomputedTablesPath: await _getPrecomputedTablesPath());
  }

  Future<String> _getWalletPath(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_userFolderName/$name';
  }

  Future<String> _getPrecomputedTablesPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_userFolderName/';
  }
}
