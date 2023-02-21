import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xelis_wallet_app/features/authentication/providers/authentication_service.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(
      authenticationNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref _ref;
}
