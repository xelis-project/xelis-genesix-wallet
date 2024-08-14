import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/locale_translate_name.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsProvider.select((state) => state.locale));
    final loc = ref.watch(appLocalizationsProvider);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: Border.all(color: Colors.transparent, width: 0),
      collapsedShape: Border.all(color: Colors.transparent, width: 0),
      title: Text(
        loc.language,
        style: context.titleLarge,
      ),
      subtitle: Text(
        translateLocaleName(locale),
        style: context.titleMedium!.copyWith(color: context.colors.primary),
      ),
      children: List<ListTile>.generate(
        AppResources.countryFlags.length,
        (index) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                AppResources.countryFlags[index],
                const SizedBox(width: Spaces.small),
                Text(
                  translateLocaleName(AppLocalizations.supportedLocales[index]),
                  style: context.titleMedium,
                )
              ],
            ),
            leading: Radio<Locale>(
              value: AppLocalizations.supportedLocales[index],
              groupValue: locale,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setLocale(value);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
