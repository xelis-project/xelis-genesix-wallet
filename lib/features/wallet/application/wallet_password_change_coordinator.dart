import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/features/wallet/domain/wallet_password_change_result.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

typedef WalletPasswordFailureRecorder =
    AppFailure Function({
      required Object error,
      required StackTrace stackTrace,
      required String operation,
      required String applicationCode,
      required AppFailureCategory category,
      String Function()? contextBuilder,
    });

AppFailure _recordWalletPasswordFailure({
  required Object error,
  required StackTrace stackTrace,
  required String operation,
  required String applicationCode,
  required AppFailureCategory category,
  String Function()? contextBuilder,
}) => recordAppFailure(
  error,
  stackTrace,
  operation: operation,
  applicationCode: applicationCode,
  applicationCategory: category,
  contextBuilder: contextBuilder,
);

/// Coordinates the native password source of truth with Genesix's optional
/// biometric credential cache.
///
/// The native dependency does not make password updates transactionally
/// reversible. After native success, a storage failure therefore disables and
/// invalidates biometric access instead of attempting a second password write.
final class WalletPasswordChangeCoordinator {
  const WalletPasswordChangeCoordinator({
    required this.changeNativePassword,
    required this.isBiometricCredentialEnabled,
    required this.persistBiometricCredential,
    required this.disableBiometricCredential,
    required this.synchronizeBiometricCredential,
    this.recordFailure = _recordWalletPasswordFailure,
  });

  final Future<void> Function(String oldPassword, String newPassword)
  changeNativePassword;
  final Future<bool> Function() isBiometricCredentialEnabled;
  final Future<void> Function(String newPassword) persistBiometricCredential;
  final Future<void> Function() disableBiometricCredential;
  final bool synchronizeBiometricCredential;
  final WalletPasswordFailureRecorder recordFailure;

  Future<WalletPasswordChangeResult> change({
    required String oldPassword,
    required String newPassword,
  }) async {
    var synchronizeCredential = false;

    if (synchronizeBiometricCredential) {
      try {
        synchronizeCredential = await isBiometricCredentialEnabled();
      } catch (error, stackTrace) {
        return WalletPasswordChangeFailure(
          recordFailure(
            error: error,
            stackTrace: stackTrace,
            operation: 'wallet.password.biometric.check',
            applicationCode: 'wallet_password_biometric_check_failed',
            category: AppFailureCategory.storageFailure,
          ),
        );
      }
    }

    try {
      await changeNativePassword(oldPassword, newPassword);
    } catch (error, stackTrace) {
      final failure = recordFailure(
        error: error,
        stackTrace: stackTrace,
        operation: 'wallet.password.change',
        applicationCode: 'wallet_password_change_failed',
        category: AppFailureCategory.operationFailure,
      );
      if (error is XelisWalletException &&
          failure.category != AppFailureCategory.authenticationOrCorruptData) {
        return WalletPasswordChangeNativeStateIndeterminate(failure);
      }
      return WalletPasswordChangeFailure(failure);
    }

    if (!synchronizeCredential) {
      return const WalletPasswordChangeSuccess();
    }

    try {
      await persistBiometricCredential(newPassword);
      return const WalletPasswordChangeSuccess();
    } catch (storageError, storageStackTrace) {
      try {
        await disableBiometricCredential();
      } catch (cleanupError, cleanupStackTrace) {
        return WalletPasswordChangedBiometricCleanupFailed(
          recordFailure(
            error: cleanupError,
            stackTrace: cleanupStackTrace,
            operation: 'wallet.password.biometric.invalidate',
            applicationCode: 'wallet_password_biometric_cleanup_failed',
            category: AppFailureCategory.storageFailure,
            contextBuilder: () =>
                'credentialWriteErrorType=${storageError.runtimeType}',
          ),
        );
      }

      return WalletPasswordChangedBiometricDisabled(
        recordFailure(
          error: storageError,
          stackTrace: storageStackTrace,
          operation: 'wallet.password.biometric.persist',
          applicationCode: 'wallet_password_biometric_persist_failed',
          category: AppFailureCategory.storageFailure,
        ),
      );
    }
  }
}
