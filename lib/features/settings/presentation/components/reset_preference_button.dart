import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';

class ResetPreferenceButton extends ConsumerStatefulWidget {
  const ResetPreferenceButton({super.key});

  @override
  ConsumerState createState() => _ResetPreferenceButtonState();
}

class _ResetPreferenceButtonState extends ConsumerState<ResetPreferenceButton> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return OutlinedButton(
        onPressed: () => _showResetPreferencesDialog(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(Spaces.medium + 4),
          side: BorderSide(
            color: context.colors.error,
            width: 1,
          ),
        ),
        child: Text(
          loc.reset_preferences,
          style: context.titleMedium!.copyWith(
              color: context.colors.error, fontWeight: FontWeight.w800),
        ));
  }

  Future<void> _resetPreferences(BuildContext context) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      await ref.read(sharedPreferencesProvider).clear();
      ref.invalidate(settingsProvider);

      ref
          .read(snackBarMessengerProvider.notifier)
          .showInfo(loc.preferences_reset_snackbar);
    } catch (e) {
      ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
    }
  }

  void _showResetPreferencesDialog(BuildContext context) {
    final loc = ref.read(appLocalizationsProvider);
    showDialog<void>(
      context: context,
      builder: (context) {
        return GenericDialog(
          // title: Text(loc.reset_preferences, style: context.titleLarge),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.reset_preferences_dialog),
              const SizedBox(height: Spaces.medium),
              Text(loc.do_you_want_to_continue,
                  style: context.bodyMedium
                      ?.copyWith(color: context.moreColors.mutedColor))
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(loc.cancel_button),
            ),
            TextButton(
              onPressed: () => context.pop(_resetPreferences(context)),
              child: Text(loc.reset),
            ),
          ],
        );
      },
    );
  }
}
