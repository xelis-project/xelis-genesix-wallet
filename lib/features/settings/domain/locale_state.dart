import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/locale_json_converter.dart';

part 'locale_state.freezed.dart';

part 'locale_state.g.dart';

@freezed
class LocaleState with _$LocaleState {
  const factory LocaleState(
    @LocaleJsonConverter() Locale locale,
  ) = _LocaleState;

  factory LocaleState.fromJson(Map<String, dynamic> json) =>
      _$LocaleStateFromJson(json);
}
