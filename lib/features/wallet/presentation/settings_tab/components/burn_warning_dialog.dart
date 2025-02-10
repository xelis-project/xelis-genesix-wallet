import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/warning_widget.dart';
import 'package:go_router/go_router.dart';

class BurnWarningDialog extends ConsumerWidget {
  const BurnWarningDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.read(appLocalizationsProvider);

    return GenericDialog(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WarningWidget([loc.burn_unlock_warning_message]),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.do_you_want_to_activate_burn_transfer,
            style: context.bodyMedium
                ?.copyWith(color: context.moreColors.mutedColor),
          ),
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
          onPressed: () => startWithBiometricAuth(
            ref,
            callback: _unlockBurn,
            reason: loc.please_authenticate_burn_tx,
            closeCurrentDialog: true,
          ),
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
