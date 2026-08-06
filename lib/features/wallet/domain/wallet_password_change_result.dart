import 'package:genesix/shared/models/app_failure.dart';

/// Outcome of changing the native wallet password and synchronizing the
/// optional biometric credential owned by Genesix.
sealed class WalletPasswordChangeResult {
  const WalletPasswordChangeResult();
}

final class WalletPasswordChangeSuccess extends WalletPasswordChangeResult {
  const WalletPasswordChangeSuccess();
}

final class WalletPasswordChangeFailure extends WalletPasswordChangeResult {
  const WalletPasswordChangeFailure(this.failure);

  final AppFailure failure;
}

/// The native call failed without a positively classified authentication
/// outcome, so whether its non-transactional metadata writes started cannot be
/// determined.
final class WalletPasswordChangeNativeStateIndeterminate
    extends WalletPasswordChangeResult {
  const WalletPasswordChangeNativeStateIndeterminate(this.failure);

  final AppFailure failure;
}

/// The native password changed and the stale biometric credential was removed.
final class WalletPasswordChangedBiometricDisabled
    extends WalletPasswordChangeResult {
  const WalletPasswordChangedBiometricDisabled(this.failure);

  final AppFailure failure;
}

/// The native password changed, but biometric credential cleanup was incomplete.
final class WalletPasswordChangedBiometricCleanupFailed
    extends WalletPasswordChangeResult {
  const WalletPasswordChangedBiometricCleanupFailed(this.failure);

  final AppFailure failure;
}
