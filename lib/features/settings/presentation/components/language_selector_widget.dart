import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/locale_translate_name.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class LanguageSelectorWidget extends ConsumerWidget {
  const LanguageSelectorWidget({
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
        loc.language,
        style: context.titleLarge,
      ),
      subtitle: Text(
        translateLocaleName(settings.locale),
        style: context.titleMedium!.copyWith(color: context.colors.primary),
      ),
      children: List<ListTile>.generate(
        AppLocalizations.supportedLocales.length,
        (index) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              CountryFlag.fromLanguageCode(
                AppLocalizations.supportedLocales[index].languageCode,
                height: 24,
                width: 30,
                borderRadius: 8,
              ),
              const SizedBox(width: Spaces.small),
              Text(
                translateLocaleName(AppLocalizations.supportedLocales[index]),
                style: context.titleMedium,
              )
            ],
          ),
          leading: Radio<Locale>(
            value: AppLocalizations.supportedLocales[index],
            groupValue: settings.locale,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setLocale(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
