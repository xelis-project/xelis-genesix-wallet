import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/settings/data/locale_state_repository.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/locale_state.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences_sync.dart';

part 'locale_state_provider.g.dart';

@riverpod
class Local extends _$Local {
  @override
  LocaleState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final localStateRepository =
        LocaleStateRepository(SharedPreferencesSync(prefs));
    final localeState = localStateRepository.fromStorage();
    return localeState;
  }

  void setLocale(Locale locale) {
    final prefs = ref.read(sharedPreferencesProvider);
    final localStateRepository =
        LocaleStateRepository(SharedPreferencesSync(prefs));
    state = state.copyWith(locale: locale);
    localStateRepository.localSave(state);
  }
}