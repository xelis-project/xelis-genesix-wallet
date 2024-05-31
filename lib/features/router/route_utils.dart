enum AppScreen {
  openWallet,
  createWallet,
  wallet,
  settings,
  changePassword,
  walletSeedScreen,
  walletSeedDialog,
  transfer,
  transactionEntry,
}

extension AppScreenExtension on AppScreen {
  String get toPath {
    switch (this) {
      case AppScreen.createWallet:
        return '/create_wallet';
      case AppScreen.openWallet:
        return '/open_wallet';
      case AppScreen.wallet:
        return '/wallet';
      case AppScreen.settings:
        return '/settings';
      case AppScreen.changePassword:
        return '/change_password';
      case AppScreen.walletSeedScreen:
        return '/wallet_seed';
      case AppScreen.walletSeedDialog:
        return '/wallet_seed_dialog';
      case AppScreen.transfer:
        return '/transfer';
      case AppScreen.transactionEntry:
        return '/transaction_entry';
    }
  }
}
