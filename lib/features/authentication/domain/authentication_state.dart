import 'package:freezed_annotation/freezed_annotation.dart';

part 'authentication_state.freezed.dart';

@freezed
sealed class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState.signedIn({required String name}) = SignedIn;

  const AuthenticationState._();

  const factory AuthenticationState.signedOut() = SignedOut;

  bool get isAuth => switch (this) {
    SignedIn() => true,
    SignedOut() => false,
  };
}
