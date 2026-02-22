import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
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
    return FButton(
      variant: .outline,
      onPress: _showResetPreferencesDialog,
      child: Text(loc.reset_preferences),
    );
  }

  Future<void> _resetPreferences(BuildContext context) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      await ref.read(sharedPreferencesProvider).clear();
      ref.invalidate(settingsProvider);

      ref
          .read(toastProvider.notifier)
          .showEvent(description: loc.preferences_reset_snackbar);
    } catch (e) {
      ref.read(toastProvider.notifier).showError(description: e.toString());
    }
  }

  void _showResetPreferencesDialog() {
    final loc = ref.read(appLocalizationsProvider);
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) {
        return FDialog(
          animation: animation,
          direction: Axis.horizontal,
          title: Text(loc.do_you_want_to_continue),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(loc.reset_preferences_dialog)],
          ),
          actions: [
            FButton(
              variant: .outline,
              onPress: () => context.pop(),
              child: Text(loc.cancel_button),
            ),
            FButton(
              onPress: () => context.pop(_resetPreferences(context)),
              child: Text(loc.confirm_button),
            ),
          ],
        );
      },
    );
  }
}
