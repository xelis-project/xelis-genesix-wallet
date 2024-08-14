enum AuthAppScreen {
  wallet,
  changePassword,
  walletSeedScreen,
  walletSeedDialog,
}

enum AppScreen {
  openWallet,
  createWallet,
  settings,
  transfer,
  burn,
  transactionEntry,
  logger,
}

extension AppScreenExtension on AppScreen {
  String get toPath {
    switch (this) {
      case AppScreen.createWallet:
        return '/create_wallet';
      case AppScreen.openWallet:
        return '/open_wallet';
      case AppScreen.settings:
        return '/settings';
      case AppScreen.transfer:
        return '/transfer';
      case AppScreen.burn:
        return '/burn';
      case AppScreen.transactionEntry:
        return '/transaction_entry';
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
    }
  }
}
