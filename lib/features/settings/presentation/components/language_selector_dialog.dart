import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class LanguageSelectorDialog extends ConsumerWidget {
  const LanguageSelectorDialog(this.style, this.animation, {super.key});

  final FDialogStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final locale = ref.watch(settingsProvider.select((state) => state.locale));
    return FDialog(
      style: style.call,
      animation: animation,
      direction: Axis.horizontal,
      body: Padding(
        padding: const EdgeInsets.all(Spaces.small),
        child: FSelect<Locale>.rich(
          control: .managed(
            initial: locale,
            onChange: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setLocale(value);
              }
            },
          ),
          label: Text(loc.language),
          description: Text(loc.select_language_config),
          format: (l) => translateLocaleName(l),
          children: List<FSelectItemMixin>.generate(
            AppResources.countryFlags.length,
            (index) {
              final locale = AppLocalizations.supportedLocales[index];
              return FSelectItem(
                title: Text(translateLocaleName(locale)),
                prefix: AppResources.countryFlags[index],
                value: AppLocalizations.supportedLocales[index],
              );
            },
          ),
        ),
      ),
      actions: [
        FButton(onPress: () => context.pop(), child: Text(loc.ok_button)),
      ],
    );
  }
}
