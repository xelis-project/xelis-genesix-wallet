import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/data/biometric_auth_repository.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_auth_provider.g.dart';

Future<void> startWithBiometricAuth(
  WidgetRef ref, {
  required void Function(WidgetRef ref) callback,
  required String reason,
  bool closeCurrentDialog = false,
  bool popOnSubmit = true,
}) async {
  final originContext = ref.context;
  var authenticated = false;
  final biometricAuthEnabled = ref.read(
    settingsProvider.select((state) => state.activateBiometricAuth),
  );

  if (!kIsWeb && biometricAuthEnabled) {
    authenticated = await ref.read(
      biometricAuthenticationProvider(reason).future,
    );
  }
  if (!originContext.mounted) return;

  if (authenticated) {
    callback(ref);
  } else {
    if (originContext.mounted) {
      await showAppDialog<void>(
        context: originContext,
        builder: (dialogContext, _, animation) {
          return PasswordDialog(
            animation,
            onValid: () {
              if (originContext.mounted && dialogContext.mounted) {
                callback(ref);
              }
            },
            closeOnValid: popOnSubmit,
          );
        },
      );
    }
  }

  if (originContext.mounted && closeCurrentDialog && originContext.canPop()) {
    originContext.pop();
  }
}

@riverpod
Future<bool> biometricAuthentication(Ref ref, String reason) async {
  final biometricAuthEnabled = ref.read(
    settingsProvider.select((state) => state.activateBiometricAuth),
  );
  if (kIsWeb || !biometricAuthEnabled) {
    return false;
  }

  final keepAliveLink = ref.keepAlive();
  final loc = ref.read(appLocalizationsProvider);
  final biometricAuthRepository = BiometricAuthRepository();
  ref.onDispose(() {
    unawaited(
      biometricAuthRepository.stopAuthentication().catchError((Object error) {
        logDiagnosticError('biometric.authentication.stop', error);
      }),
    );
  });

  try {
    final canAuthenticate = await biometricAuthRepository.canAuthenticate();
    if (!ref.mounted) return false;

    if (!canAuthenticate) {
      talker.info('Biometric authentication not available');
      return false;
    }

    try {
      return await biometricAuthRepository.authenticate(reason);
    } on LocalAuthException catch (e, stackTrace) {
      if (!ref.mounted) return false;

      if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
        logDiagnosticError('biometric.authentication.authenticate', e);
        ref
            .read(toastProvider.notifier)
            .showWarning(title: loc.biometric_not_available_warning);
      } else if (e.code == LocalAuthExceptionCode.temporaryLockout ||
          e.code == LocalAuthExceptionCode.biometricLockout) {
        logDiagnosticError('biometric.authentication.authenticate', e);
        ref
            .read(toastProvider.notifier)
            .showWarning(title: loc.biometric_auth_temporarily_locked);
      } else {
        final failure = recordAppFailure(
          e,
          stackTrace,
          operation: 'biometric.authentication.authenticate',
          applicationCode: 'biometric_authentication_failed',
        );
        ref
            .read(toastProvider.notifier)
            .showFailure(title: loc.authentication, failure: failure);
      }
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;

      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'biometric.authentication.authenticate',
        applicationCode: 'biometric_authentication_failed',
      );
      ref
          .read(toastProvider.notifier)
          .showFailure(title: loc.authentication, failure: failure);
    }
  } finally {
    keepAliveLink.close();
  }

  talker.info('Biometric authentication not available');
  return false;
}
