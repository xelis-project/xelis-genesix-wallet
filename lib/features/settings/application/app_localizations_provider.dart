import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:genesix/features/settings/application/settings_state_provider.dart';

part 'app_localizations_provider.g.dart';

@riverpod
AppLocalizations appLocalizations(Ref ref) {
  final locale = ref.watch(settingsProvider.select((state) => state.locale));
  return lookupAppLocalizations(locale);
}
