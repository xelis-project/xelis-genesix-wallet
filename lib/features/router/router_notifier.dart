import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(
      authenticationNotifierProvider,
      (previous, next) => notifyListeners(),
    );
  }

  final Ref _ref;
}
