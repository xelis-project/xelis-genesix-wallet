import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_mode_state.freezed.dart';
part 'theme_mode_state.g.dart';

@freezed
class ThemeModeState with _$ThemeModeState {
  const factory ThemeModeState(ThemeMode themeMode) = _ThemeModeState;

  factory ThemeModeState.fromJson(Map<String, dynamic> json) =>
      _$ThemeModeStateFromJson(json);
}
