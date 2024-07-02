import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/locale_translate_name.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({
    super.key,
  });

  CountryFlag getCountryFlag(int index) {
    String languageCode = AppLocalizations.supportedLocales[index].languageCode;
    switch (languageCode) {
      case 'zh':
        return CountryFlag.fromCountryCode(
          'CN',
          height: 24,
          width: 30,
          shape: const RoundedRectangle(8),
        );
      case 'ru' || 'pt' || 'nl' || 'pl':
        return CountryFlag.fromCountryCode(
          languageCode,
          height: 24,
          width: 30,
          shape: const RoundedRectangle(8),
        );
      case 'ko':
        return CountryFlag.fromCountryCode(
          'KR',
          height: 24,
          width: 30,
          shape: const RoundedRectangle(8),
        );
      case 'ms':
        return CountryFlag.fromCountryCode(
          'MY',
          height: 24,
          width: 30,
          shape: const RoundedRectangle(8),
        );
      case 'uk':
        return CountryFlag.fromCountryCode(
          'UA',
          height: 24,
          width: 30,
          shape: const RoundedRectangle(8),
        );
      case 'ja':
        return CountryFlag.fromCountryCode(
          'JP',
          height: 24,
          width: 30,
          shape: const RoundedRectangle(8),
        );
      default:
        return CountryFlag.fromLanguageCode(
          AppLocalizations.supportedLocales[index].languageCode,
          height: 24,
          width: 30,
          shape: const RoundedRectangle(8),
        );
    }
  }

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
        AppLocalizations.supportedLocales.length,
        (index) {
          CountryFlag countryFlag = getCountryFlag(index);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                countryFlag,
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
