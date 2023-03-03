// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_ThemeModeState _$$_ThemeModeStateFromJson(Map<String, dynamic> json) =>
    _$_ThemeModeState(
      $enumDecode(_$ThemeModeEnumMap, json['themeMode']),
    );

Map<String, dynamic> _$$_ThemeModeStateToJson(_$_ThemeModeState instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
