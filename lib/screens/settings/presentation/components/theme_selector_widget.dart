import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/settings_state.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/theme_translate_name.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

const List<AppTheme> themes = <AppTheme>[
  AppTheme.xelis,
  AppTheme.dark,
  AppTheme.light,
];

class ThemeWidget extends ConsumerWidget {
  const ThemeWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final loc = ref.watch(appLocalizationsProvider);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: Border.all(color: Colors.transparent, width: 0),
      collapsedShape: Border.all(color: Colors.transparent, width: 0),
      title: Text(
        loc.theme,
        style: context.titleLarge,
      ),
      subtitle: Text(
        translateThemeName(loc, settings.theme),
        style: context.titleMedium!.copyWith(color: context.colors.primary),
      ),
      children: List<ListTile>.generate(
        themes.length,
        (index) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            translateThemeName(loc, themes[index]),
            style: context.titleMedium,
          ),
          leading: Radio<AppTheme>(
            value: themes[index],
            groupValue: settings.theme,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setTheme(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
