enum AppScreen {
  auth,
  hub,
  changePassword,
}

extension AppScreenExtension on AppScreen {
  String get toPath {
    switch (this) {
      case AppScreen.auth:
        return '/login';
      case AppScreen.hub:
        return '/hub';
      case AppScreen.changePassword:
        return '/change_password';
    }
  }

  String get toName {
    switch (this) {
      case AppScreen.auth:
        return 'authentication';
      case AppScreen.hub:
        return 'hub';
      case AppScreen.changePassword:
        return 'change_password';
    }
  }

  String get toTitle {
    switch (this) {
      case AppScreen.auth:
        return 'XELIS Wallet Authentication';
      case AppScreen.hub:
        return 'XELIS Wallet';
      case AppScreen.changePassword:
        return 'Change Password';
    }
  }
}
