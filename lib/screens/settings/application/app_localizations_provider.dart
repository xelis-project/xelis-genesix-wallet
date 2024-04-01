import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';

part 'app_localizations_provider.g.dart';

@riverpod
AppLocalizations appLocalizations(AppLocalizationsRef ref) {
  final settings = ref.watch(settingsProvider);
  return lookupAppLocalizations(settings.locale);
}
