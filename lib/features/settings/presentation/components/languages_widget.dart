import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/locale_state_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/locale_translate_name.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class LanguageWidget extends ConsumerWidget {
  const LanguageWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localizationProvider);
    final loc = ref.watch(appLocalizationsProvider);
    return ExpansionTile(
      title: Text(
        loc.language,
        style: context.titleLarge,
      ),
      subtitle: Text(
        translateLocaleName(currentLocale.locale),
        style: context.titleMedium,
      ),
      children: List<ListTile>.generate(
        AppLocalizations.supportedLocales.length,
        (index) => ListTile(
          title: Text(
            translateLocaleName(AppLocalizations.supportedLocales[index]),
            style: context.titleMedium,
          ),
          leading: Radio<Locale>(
            value: AppLocalizations.supportedLocales[index],
            groupValue: currentLocale.locale,
            onChanged: (value) {
              if (value != null) {
                ref.read(localizationProvider.notifier).setLocale(value);
              }
            },
          ),
        ),
      ),
    );
  }
}
