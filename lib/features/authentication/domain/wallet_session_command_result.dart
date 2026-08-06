import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_session_command_result.freezed.dart';

@freezed
sealed class WalletSessionFailure with _$WalletSessionFailure {
  const factory WalletSessionFailure.walletAlreadyExists() =
      WalletAlreadyExistsSessionFailure;

  const factory WalletSessionFailure.walletNotFound() =
      WalletNotFoundSessionFailure;

  const factory WalletSessionFailure.invalidWalletFolder() =
      InvalidWalletFolderSessionFailure;

  const factory WalletSessionFailure.xelis() = XelisWalletSessionFailure;

  const factory WalletSessionFailure.unknown() = UnknownWalletSessionFailure;
}

@freezed
sealed class WalletSessionCommandResult with _$WalletSessionCommandResult {
  const WalletSessionCommandResult._();

  const factory WalletSessionCommandResult.success({
    required String name,
    String? seedToReveal,
  }) = WalletSessionCommandSuccess;

  const factory WalletSessionCommandResult.failure(
    WalletSessionFailure failure,
  ) = WalletSessionCommandFailure;

  bool get isSuccess => this is WalletSessionCommandSuccess;
}
