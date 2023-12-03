import 'package:freezed_annotation/freezed_annotation.dart';

part 'authentication_state.freezed.dart';

@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState.signedIn({
    required int walletId,
    required List<int> secretKey,
  }) = SignedIn;

  const AuthenticationState._();

  const factory AuthenticationState.signedOut({
    int? walletId,
    List<int>? secretKey,
  }) = SignedOut;

  bool get isAuth => switch (this) {
        SignedIn() => true,
        SignedOut() => false,
        AuthenticationState() => false,
      };
}
