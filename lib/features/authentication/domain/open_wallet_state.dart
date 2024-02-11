import 'package:freezed_annotation/freezed_annotation.dart';

part 'open_wallet_state.freezed.dart';

part 'open_wallet_state.g.dart';

@freezed
class OpenWalletState with _$OpenWalletState {
  const factory OpenWalletState({
    String? walletCurrentlyUsed,
    @Default({}) Map<String, String> wallets,
  }) = _OpenWalletState;

  factory OpenWalletState.fromJson(Map<String, dynamic> json) =>
      _$OpenWalletStateFromJson(json);
}
