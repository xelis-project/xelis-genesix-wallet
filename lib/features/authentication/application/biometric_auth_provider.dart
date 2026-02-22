import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/data/biometric_auth_repository.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
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
  var authenticated = false;
  if (!kIsWeb) {
    authenticated = await ref.read(
      biometricAuthenticationProvider(reason).future,
    );
  }
  if (authenticated) {
    callback(ref);
  } else {
    if (ref.context.mounted) {
      await showAppDialog<void>(
        context: ref.context,
        builder: (context, _, animation) {
          return PasswordDialog(
            animation,
            onValid: () => callback(ref),
            closeOnValid: popOnSubmit,
          );
        },
      );
    }
  }

  if (ref.context.mounted && closeCurrentDialog) {
    ref.context.pop();
  }
}

@riverpod
Future<bool> biometricAuthentication(Ref ref, String reason) async {
  final loc = ref.read(appLocalizationsProvider);
  final biometricAuthRepository = BiometricAuthRepository();

  if (await biometricAuthRepository.canAuthenticate()) {
    try {
      return await biometricAuthRepository.authenticate(reason);
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.noBiometricHardware) {
        talker.warning('BiometricAuthentication', e);
        ref
            .read(toastProvider.notifier)
            .showWarning(title: loc.biometric_not_available_warning);
      } else if (e.code == LocalAuthExceptionCode.temporaryLockout ||
          e.code == LocalAuthExceptionCode.biometricLockout) {
        talker.warning('BiometricAuthentication', e);
        ref
            .read(toastProvider.notifier)
            .showWarning(
              title:
                  'Biometric authentication is temporarily locked. Please try again later.',
            );
      } else {
        talker.warning('BiometricAuthentication', e);
        ref
            .read(toastProvider.notifier)
            .showWarning(
              title: e.description ?? 'Biometric authentication failed',
            );
      }
    } catch (e) {
      talker.error('BiometricAuthentication', e);
      ref.read(toastProvider.notifier).showError(description: e.toString());
    }
  }
  talker.info('Biometric authentication not available');
  return false;
}
