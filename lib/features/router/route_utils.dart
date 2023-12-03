enum AppScreen {
  // splash,
  auth,
  hub,
  settings,
}

extension AppScreenExtension on AppScreen {
  String get toPath {
    switch (this) {
      case AppScreen.auth:
        return '/login';
      case AppScreen.hub:
        return '/hub';
      case AppScreen.settings:
        return '/settings';
    }
  }

  String get toName {
    switch (this) {
      case AppScreen.auth:
        return 'authentication';
      case AppScreen.hub:
        return 'hub';
      case AppScreen.settings:
        return 'settings';
    }
  }

  String get toTitle {
    switch (this) {
      case AppScreen.auth:
        return 'Xelis Wallet Authentication';
      case AppScreen.hub:
        return 'Xelis Wallet';
      case AppScreen.settings:
        return 'Settings';
    }
  }
}
