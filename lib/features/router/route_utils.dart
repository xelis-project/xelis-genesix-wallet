enum AuthAppScreen {
  home,
  settings,
  network,
  history,
  assets,
  recoveryPhrase,
  transfer,
  burn,
  multisig,
  transactionEntry,
  xswdStatus,
  addressBook,
}

enum AppScreen { openWallet, createWallet, importWallet, lightSettings }

extension AppScreenExtension on AppScreen {
  String get toPath {
    switch (this) {
      case AppScreen.openWallet:
        return '/';
      case AppScreen.createWallet:
        return '/create_wallet';
      case AppScreen.importWallet:
        return '/import_wallet';
      case AppScreen.lightSettings:
        return '/light_settings';
    }
  }

  static AppScreen fromPath(String path) {
    return AppScreen.values.firstWhere((screen) => screen.toPath == path);
  }
}

extension AuthAppScreenExtension on AuthAppScreen {
  String get toPath {
    switch (this) {
      case AuthAppScreen.home:
        return '/home';
      case AuthAppScreen.settings:
        return '/settings';
      case AuthAppScreen.network:
        return '/network';
      case AuthAppScreen.history:
        return '/history';
      case AuthAppScreen.assets:
        return '/assets';
      case AuthAppScreen.recoveryPhrase:
        return '/recovery_phrase';
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

  static AuthAppScreen fromPath(String path) {
    return AuthAppScreen.values.firstWhere((screen) => screen.toPath == path);
  }
}
