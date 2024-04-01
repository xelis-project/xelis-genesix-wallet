enum AppScreen {
  openWallet,
  createWallet,
  wallet,
  settings,
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
    }
  }

  String get toName {
    switch (this) {
      case AppScreen.createWallet:
        return 'create_wallet';
      case AppScreen.openWallet:
        return 'open_wallet';
      case AppScreen.wallet:
        return 'wallet';
      case AppScreen.settings:
        return 'settings';
    }
  }

  String get toTitle {
    switch (this) {
      case AppScreen.createWallet:
        return 'Create Wallet';
      case AppScreen.openWallet:
        return 'Open Wallet';
      case AppScreen.wallet:
        return 'Wallet';
      case AppScreen.settings:
        return 'Settings';
    }
  }
}
