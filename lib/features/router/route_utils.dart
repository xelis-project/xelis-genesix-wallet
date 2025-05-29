enum AuthAppScreen {
  wallet,
  changePassword,
  walletSeedScreen,
  walletSeedDialog,
  transfer,
  burn,
  multisig,
  transactionEntry,
  xswdStatus,
  addressBook,
}

enum AppScreen {
  openWallet,
  createNewWallet,
  recoverWalletFromSeed1,
  recoverWalletFromSeed2,
  recoverWalletFromPrivateKey,
  settings,
  logger,
}

extension AppScreenExtension on AppScreen {
  String get toPath {
    switch (this) {
      case AppScreen.createNewWallet:
        return '/create_new_wallet';
      case AppScreen.recoverWalletFromSeed1:
        return '/recover_wallet_from_seed/1';
      case AppScreen.recoverWalletFromSeed2:
        return '/recover_wallet_from_seed/2';
      case AppScreen.recoverWalletFromPrivateKey:
        return '/recover_wallet_from_private_key';
      case AppScreen.openWallet:
        return '/open_wallet';
      case AppScreen.settings:
        return '/settings';
      case AppScreen.logger:
        return '/logger';
    }
  }
}

extension AuthAppScreenExtension on AuthAppScreen {
  String get toPath {
    switch (this) {
      case AuthAppScreen.wallet:
        return '/wallet';
      case AuthAppScreen.changePassword:
        return '/change_password';
      case AuthAppScreen.walletSeedScreen:
        return '/wallet_seed';
      case AuthAppScreen.walletSeedDialog:
        return '/wallet_seed_dialog';
      case AuthAppScreen.transfer:
        return '/transfer';
      case AuthAppScreen.burn:
        return '/burn';
      case AuthAppScreen.transactionEntry:
        return '/transaction_entry';
      case AuthAppScreen.multisig:
        return '/multisig';
      case AuthAppScreen.xswdStatus:
        return '/xswd_status';
      case AuthAppScreen.addressBook:
        return '/address_book';
    }
  }
}
