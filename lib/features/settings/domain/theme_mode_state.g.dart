// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThemeModeStateImpl _$$ThemeModeStateImplFromJson(Map<String, dynamic> json) =>
    _$ThemeModeStateImpl(
      $enumDecode(_$ThemeModeEnumMap, json['themeMode']),
    );

Map<String, dynamic> _$$ThemeModeStateImplToJson(
        _$ThemeModeStateImpl instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
