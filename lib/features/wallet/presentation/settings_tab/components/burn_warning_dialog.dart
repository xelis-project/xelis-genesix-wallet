import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:go_router/go_router.dart';

class BurnWarningDialog extends ConsumerWidget {
  const BurnWarningDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.read(appLocalizationsProvider);

    return AlertDialog(
      scrollable: true,
      elevation: 10,
      contentPadding: const EdgeInsets.all(Spaces.medium),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.primary),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: context.colors.primary,
                        size: 30,
                      ),
                      const SizedBox(width: Spaces.medium),
                      Expanded(
                          child: Text(loc.warning,
                              style: context.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.primary))),
                    ],
                  ),
                  const SizedBox(height: Spaces.small),
                  Text(
                    loc.burn_transfer_warning_message,
                    style: context.bodyMedium
                        ?.copyWith(color: context.colors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spaces.medium),
          Text(loc.do_you_want_to_activate_burn_transfer),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(settingsProvider.notifier).setUnlockBurn(false);
            context.pop();
          },
          child: Text(loc.cancel_button),
        ),
        TextButton(
          onPressed: () => startWithBiometricAuth(ref, callback: _unlockBurn),
          child: Text(loc.confirm_button),
        ),
      ],
    );
  }

  void _unlockBurn(WidgetRef ref) {
    final loc = ref.read(appLocalizationsProvider);
    ref.read(settingsProvider.notifier).setUnlockBurn(true);
    ref
        .read(snackBarMessengerProvider.notifier)
        .showInfo(loc.burn_transfer_unlock);
  }
}
