import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/data/biometric_auth_repository.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/error_codes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_auth_provider.g.dart';

Future<void> startWithBiometricAuth(
  WidgetRef ref, {
  required void Function(WidgetRef ref) callback,
  required String reason,
  bool closeCurrentDialog = false,
}) async {
  var authenticated = false;
  if (!kIsWeb) {
    authenticated = await ref
        .read(biometricAuthProvider.notifier)
        .authenticate(reason);
  }
  if (authenticated) {
    callback(ref);
  } else {
    if (ref.context.mounted) {
      await showFDialog<void>(
        context: ref.context,
        builder: (context, style, animation) {
          return PasswordDialog(style, animation, onValid: () => callback(ref));
        },
      );
    }
  }

  if (ref.context.mounted && closeCurrentDialog) {
    ref.context.pop();
  }
}

enum BiometricAuthProviderStatus { ready, locked, stopped }

@riverpod
class BiometricAuth extends _$BiometricAuth {
  final _biometricAuthRepository = BiometricAuthRepository();

  @override
  BiometricAuthProviderStatus build() {
    final bool biometricAuthUnlock = ref.watch(
      settingsProvider.select((s) => s.activateBiometricAuth),
    );

    ref.keepAlive();

    if (!biometricAuthUnlock) {
      return BiometricAuthProviderStatus.stopped;
    } else {
      return BiometricAuthProviderStatus.ready;
    }
  }

  Future<bool> authenticate(String reason) async {
    final loc = ref.read(appLocalizationsProvider);
    if (await _biometricAuthRepository.canAuthenticate() &&
        state == BiometricAuthProviderStatus.ready) {
      try {
        return await _biometricAuthRepository.authenticate(reason);
      } on PlatformException catch (e) {
        talker.warning('BiometricAuthProvider:authenticate', e);
        if (e.code == lockedOut || e.code == permanentlyLockedOut) {
          state = BiometricAuthProviderStatus.locked;
          ref
              .read(toastProvider.notifier)
              .showWarning(title: loc.biometric_locked_warning);
        } else if (e.message != null && !e.message!.contains('canceled')) {
          ref
              .read(toastProvider.notifier)
              .showWarning(title: loc.biometric_not_available_warning);
        }
      } catch (e) {
        talker.error('BiometricAuthProvider:authenticate', e);
        ref.read(toastProvider.notifier).showError(description: e.toString());
      }
    }
    return false;
  }

  void updateStatus(BiometricAuthProviderStatus status) {
    state = status;
  }
}
