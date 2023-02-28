import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthenticationNotifier extends StateNotifier<bool> {
  AuthenticationNotifier(super.state);

  void login() {
    state = true;
  }

  void logout() {
    state = false;
  }
}

final authenticationNotifierProvider =
    StateNotifierProvider<AuthenticationNotifier, bool>(
  (ref) => AuthenticationNotifier(false),
);
