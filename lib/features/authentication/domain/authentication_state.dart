import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';

part 'authentication_state.freezed.dart';

@freezed
sealed class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState.signedIn({
    required String name,
    required NativeWalletRepository nativeWallet,
  }) = SignedIn;

  const AuthenticationState._();

  const factory AuthenticationState.signedOut() = SignedOut;

  bool get isAuth => switch (this) {
    SignedIn() => true,
    SignedOut() => false,
  };
}
