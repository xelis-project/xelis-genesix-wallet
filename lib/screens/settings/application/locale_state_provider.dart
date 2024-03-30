import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/screens/settings/data/locale_state_repository.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/locale_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

part 'locale_state_provider.g.dart';

@riverpod
class Localization extends _$Localization {
  @override
  LocaleState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final localeStateRepository =
        LocaleStateRepository(SharedPreferencesSync(prefs));
    return localeStateRepository.fromStorage();
  }

  void setLocale(Locale locale) {
    final prefs = ref.read(sharedPreferencesProvider);
    final localeStateRepository =
        LocaleStateRepository(SharedPreferencesSync(prefs));
    state = state.copyWith(locale: locale);
    localeStateRepository.localSave(state);
  }
}
