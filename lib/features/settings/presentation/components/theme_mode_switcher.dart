import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/theme/constants.dart';

class ThemeModeSwitcher extends ConsumerWidget {
  const ThemeModeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final appTheme = ref.watch(
      settingsProvider.select((state) => state.appTheme),
    );
    final isDarkMode = appTheme == AppTheme.dark || appTheme == AppTheme.xelis;
    final futureAppTheme = isDarkMode ? AppTheme.light : AppTheme.dark;
    return Padding(
      padding: const EdgeInsets.all(Spaces.small),
      child: FTooltip(
        tipBuilder: (context, controller) =>
            Text(loc.switch_theme_mode(futureAppTheme.name)),
        child: FHeaderAction(
          icon: AnimatedSwitcher(
            duration: Duration(milliseconds: AppDurations.animFast),
            key: ValueKey(isDarkMode),
            child: Icon(isDarkMode ? FIcons.sun : FIcons.moon),
          ),
          onPress: () {
            ref.read(settingsProvider.notifier).setTheme(futureAppTheme);
          },
        ),
      ),
    );
  }
}
