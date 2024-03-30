enum AppScreen {
  auth,
  wallet,
  settings,
}

extension AppScreenExtension on AppScreen {
  String get toPath {
    switch (this) {
      case AppScreen.auth:
        return '/auth';
      case AppScreen.wallet:
        return '/wallet';
      case AppScreen.settings:
        return '/settings';
    }
  }

  String get toName {
    switch (this) {
      case AppScreen.auth:
        return 'authentication';
      case AppScreen.wallet:
        return 'wallet';
      case AppScreen.settings:
        return 'settings';
    }
  }

  String get toTitle {
    switch (this) {
      case AppScreen.auth:
        return 'Authentication';
      case AppScreen.wallet:
        return 'Wallet';
      case AppScreen.settings:
        return 'Settings';
    }
  }
}
