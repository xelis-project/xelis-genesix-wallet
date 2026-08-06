import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/wallet_password_change_coordinator.dart';
import 'package:genesix/features/wallet/domain/wallet_password_change_result.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test(
    'does not persist a password when biometric access is disabled',
    () async {
      final recorder = _RecordingFailureRecorder();
      final calls = <String>[];
      String? receivedOldPassword;
      String? receivedNewPassword;
      final coordinator = WalletPasswordChangeCoordinator(
        synchronizeBiometricCredential: true,
        isBiometricCredentialEnabled: () async => false,
        changeNativePassword: (oldPassword, newPassword) async {
          calls.add('native');
          receivedOldPassword = oldPassword;
          receivedNewPassword = newPassword;
        },
        persistBiometricCredential: (_) async => calls.add('persist'),
        disableBiometricCredential: () async => calls.add('disable'),
        recordFailure: recorder.call,
      );

      final result = await coordinator.change(
        oldPassword: ' old password ',
        newPassword: ' new password ',
      );

      expect(result, isA<WalletPasswordChangeSuccess>());
      expect(calls, ['native']);
      expect(receivedOldPassword, ' old password ');
      expect(receivedNewPassword, ' new password ');
      expect(recorder.records, isEmpty);
    },
  );

  test(
    'does not mutate the wallet when the biometric flag cannot be read',
    () async {
      final recorder = _RecordingFailureRecorder();
      var nativeCalls = 0;
      final coordinator = WalletPasswordChangeCoordinator(
        synchronizeBiometricCredential: true,
        isBiometricCredentialEnabled: () async => throw StateError('storage'),
        changeNativePassword: (_, _) async => nativeCalls++,
        persistBiometricCredential: (_) async {},
        disableBiometricCredential: () async {},
        recordFailure: recorder.call,
      );

      final result = await coordinator.change(
        oldPassword: 'old',
        newPassword: 'new',
      );

      expect(result, isA<WalletPasswordChangeFailure>());
      expect(nativeCalls, 0);
      expect(recorder.records, hasLength(1));
      expect(
        recorder.records.single.operation,
        'wallet.password.biometric.check',
      );
    },
  );

  test('preserves a native password-change failure and support id', () async {
    final recorder = _RecordingFailureRecorder();
    const nativeFailure = XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.walletPasswordChange,
      code: XelisWalletErrorCode.authenticationOrCorruptData,
      supportId: 'XWF-1111-2222-3333-4444-5555',
    );
    final coordinator = WalletPasswordChangeCoordinator(
      synchronizeBiometricCredential: false,
      isBiometricCredentialEnabled: () async => false,
      changeNativePassword: (_, _) async => throw nativeFailure,
      persistBiometricCredential: (_) async {},
      disableBiometricCredential: () async {},
      recordFailure: recorder.call,
    );

    final result = await coordinator.change(
      oldPassword: 'old',
      newPassword: 'new',
    );

    expect(result, isA<WalletPasswordChangeFailure>());
    final failure = (result as WalletPasswordChangeFailure).failure;
    expect(failure.source, 'xelisWallet');
    expect(failure.operation, 'wallet.password.change');
    expect(failure.code, 'wallet.authentication_or_corrupt_data');
    expect(failure.supportId, nativeFailure.supportId);
    expect(recorder.records, hasLength(1));
  });

  test('treats a non-auth native failure as an indeterminate state', () async {
    final recorder = _RecordingFailureRecorder();
    const nativeFailure = XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.walletPasswordChange,
      code: XelisWalletErrorCode.internal,
      supportId: 'XWF-AAAA-BBBB-CCCC-DDDD-EEEE',
    );
    final coordinator = WalletPasswordChangeCoordinator(
      synchronizeBiometricCredential: true,
      isBiometricCredentialEnabled: () async => true,
      changeNativePassword: (_, _) async => throw nativeFailure,
      persistBiometricCredential: (_) async =>
          fail('must not persist an indeterminate password'),
      disableBiometricCredential: () async =>
          fail('must not mutate biometric state after unconfirmed native work'),
      recordFailure: recorder.call,
    );

    final result = await coordinator.change(
      oldPassword: 'old secret',
      newPassword: 'new secret',
    );

    expect(result, isA<WalletPasswordChangeNativeStateIndeterminate>());
    expect(recorder.records, hasLength(1));
    expect(recorder.records.single.operation, 'wallet.password.change');
  });

  test('keeps a pre-native Dart failure determinate', () async {
    final recorder = _RecordingFailureRecorder();
    final coordinator = WalletPasswordChangeCoordinator(
      synchronizeBiometricCredential: false,
      isBiometricCredentialEnabled: () async => false,
      changeNativePassword: (_, _) async => throw StateError('closed handle'),
      persistBiometricCredential: (_) async {},
      disableBiometricCredential: () async {},
      recordFailure: recorder.call,
    );

    final result = await coordinator.change(
      oldPassword: 'old secret',
      newPassword: 'new secret',
    );

    expect(result, isA<WalletPasswordChangeFailure>());
    expect(recorder.records, hasLength(1));
  });

  test('persists the new credential after native success', () async {
    final recorder = _RecordingFailureRecorder();
    final calls = <String>[];
    final coordinator = WalletPasswordChangeCoordinator(
      synchronizeBiometricCredential: true,
      isBiometricCredentialEnabled: () async => true,
      changeNativePassword: (_, _) async => calls.add('native'),
      persistBiometricCredential: (_) async => calls.add('persist'),
      disableBiometricCredential: () async => calls.add('disable'),
      recordFailure: recorder.call,
    );

    final result = await coordinator.change(
      oldPassword: 'old',
      newPassword: 'new',
    );

    expect(result, isA<WalletPasswordChangeSuccess>());
    expect(calls, ['native', 'persist']);
    expect(recorder.records, isEmpty);
  });

  test('disables biometric access when credential persistence fails', () async {
    final recorder = _RecordingFailureRecorder();
    final calls = <String>[];
    final coordinator = WalletPasswordChangeCoordinator(
      synchronizeBiometricCredential: true,
      isBiometricCredentialEnabled: () async => true,
      changeNativePassword: (_, _) async => calls.add('native'),
      persistBiometricCredential: (_) async {
        calls.add('persist');
        throw StateError('storage');
      },
      disableBiometricCredential: () async => calls.add('disable'),
      recordFailure: recorder.call,
    );

    final result = await coordinator.change(
      oldPassword: 'old',
      newPassword: 'new',
    );

    expect(result, isA<WalletPasswordChangedBiometricDisabled>());
    expect(calls, ['native', 'persist', 'disable']);
    expect(recorder.records, hasLength(1));
    expect(
      recorder.records.single.operation,
      'wallet.password.biometric.persist',
    );
  });

  test(
    'reports incomplete biometric cleanup as a distinct partial outcome',
    () async {
      final recorder = _RecordingFailureRecorder();
      final coordinator = WalletPasswordChangeCoordinator(
        synchronizeBiometricCredential: true,
        isBiometricCredentialEnabled: () async => true,
        changeNativePassword: (_, _) async {},
        persistBiometricCredential: (_) async => throw StateError('write'),
        disableBiometricCredential: () async => throw StateError('cleanup'),
        recordFailure: recorder.call,
      );

      final result = await coordinator.change(
        oldPassword: 'old secret',
        newPassword: 'new secret',
      );

      expect(result, isA<WalletPasswordChangedBiometricCleanupFailed>());
      expect(recorder.records, hasLength(1));
      final record = recorder.records.single;
      expect(record.operation, 'wallet.password.biometric.invalidate');
      expect(record.context, 'credentialWriteErrorType=StateError');
      expect(record.failure.toString(), isNot(contains('old secret')));
      expect(record.failure.toString(), isNot(contains('new secret')));
    },
  );
}

final class _RecordingFailureRecorder {
  final records = <_FailureRecord>[];

  AppFailure call({
    required Object error,
    required StackTrace stackTrace,
    required String operation,
    required String applicationCode,
    required AppFailureCategory category,
    String Function()? contextBuilder,
  }) {
    final failure = error is XelisWalletException
        ? AppFailure.fromXelis(error)
        : AppFailure.application(
            operation: operation,
            code: applicationCode,
            exceptionType: error.runtimeType.toString(),
            category: category,
          );
    records.add(
      _FailureRecord(
        failure: failure,
        operation: operation,
        context: contextBuilder?.call(),
      ),
    );
    return failure;
  }
}

final class _FailureRecord {
  const _FailureRecord({
    required this.failure,
    required this.operation,
    required this.context,
  });

  final AppFailure failure;
  final String operation;
  final String? context;
}
