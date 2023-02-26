// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$Settings {
  bool get isDarkMode => throw _privateConstructorUsedError;
  String get languageSelected => throw _privateConstructorUsedError;
  String get daemonAddressSelected => throw _privateConstructorUsedError;
  List<String> get daemonAddresses => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SettingsCopyWith<Settings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsCopyWith<$Res> {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) then) =
      _$SettingsCopyWithImpl<$Res, Settings>;
  @useResult
  $Res call(
      {bool isDarkMode,
      String languageSelected,
      String daemonAddressSelected,
      List<String> daemonAddresses});
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res, $Val extends Settings>
    implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isDarkMode = null,
    Object? languageSelected = null,
    Object? daemonAddressSelected = null,
    Object? daemonAddresses = null,
  }) {
    return _then(_value.copyWith(
      isDarkMode: null == isDarkMode
          ? _value.isDarkMode
          : isDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      languageSelected: null == languageSelected
          ? _value.languageSelected
          : languageSelected // ignore: cast_nullable_to_non_nullable
              as String,
      daemonAddressSelected: null == daemonAddressSelected
          ? _value.daemonAddressSelected
          : daemonAddressSelected // ignore: cast_nullable_to_non_nullable
              as String,
      daemonAddresses: null == daemonAddresses
          ? _value.daemonAddresses
          : daemonAddresses // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_SettingsCopyWith<$Res> implements $SettingsCopyWith<$Res> {
  factory _$$_SettingsCopyWith(
          _$_Settings value, $Res Function(_$_Settings) then) =
      __$$_SettingsCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isDarkMode,
      String languageSelected,
      String daemonAddressSelected,
      List<String> daemonAddresses});
}

/// @nodoc
class __$$_SettingsCopyWithImpl<$Res>
    extends _$SettingsCopyWithImpl<$Res, _$_Settings>
    implements _$$_SettingsCopyWith<$Res> {
  __$$_SettingsCopyWithImpl(
      _$_Settings _value, $Res Function(_$_Settings) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isDarkMode = null,
    Object? languageSelected = null,
    Object? daemonAddressSelected = null,
    Object? daemonAddresses = null,
  }) {
    return _then(_$_Settings(
      isDarkMode: null == isDarkMode
          ? _value.isDarkMode
          : isDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      languageSelected: null == languageSelected
          ? _value.languageSelected
          : languageSelected // ignore: cast_nullable_to_non_nullable
              as String,
      daemonAddressSelected: null == daemonAddressSelected
          ? _value.daemonAddressSelected
          : daemonAddressSelected // ignore: cast_nullable_to_non_nullable
              as String,
      daemonAddresses: null == daemonAddresses
          ? _value._daemonAddresses
          : daemonAddresses // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc

class _$_Settings with DiagnosticableTreeMixin implements _Settings {
  const _$_Settings(
      {required this.isDarkMode,
      required this.languageSelected,
      required this.daemonAddressSelected,
      required final List<String> daemonAddresses})
      : _daemonAddresses = daemonAddresses;

  @override
  final bool isDarkMode;
  @override
  final String languageSelected;
  @override
  final String daemonAddressSelected;
  final List<String> _daemonAddresses;
  @override
  List<String> get daemonAddresses {
    if (_daemonAddresses is EqualUnmodifiableListView) return _daemonAddresses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_daemonAddresses);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Settings(isDarkMode: $isDarkMode, languageSelected: $languageSelected, daemonAddressSelected: $daemonAddressSelected, daemonAddresses: $daemonAddresses)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Settings'))
      ..add(DiagnosticsProperty('isDarkMode', isDarkMode))
      ..add(DiagnosticsProperty('languageSelected', languageSelected))
      ..add(DiagnosticsProperty('daemonAddressSelected', daemonAddressSelected))
      ..add(DiagnosticsProperty('daemonAddresses', daemonAddresses));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_Settings &&
            (identical(other.isDarkMode, isDarkMode) ||
                other.isDarkMode == isDarkMode) &&
            (identical(other.languageSelected, languageSelected) ||
                other.languageSelected == languageSelected) &&
            (identical(other.daemonAddressSelected, daemonAddressSelected) ||
                other.daemonAddressSelected == daemonAddressSelected) &&
            const DeepCollectionEquality()
                .equals(other._daemonAddresses, _daemonAddresses));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isDarkMode,
      languageSelected,
      daemonAddressSelected,
      const DeepCollectionEquality().hash(_daemonAddresses));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SettingsCopyWith<_$_Settings> get copyWith =>
      __$$_SettingsCopyWithImpl<_$_Settings>(this, _$identity);
}

abstract class _Settings implements Settings {
  const factory _Settings(
      {required final bool isDarkMode,
      required final String languageSelected,
      required final String daemonAddressSelected,
      required final List<String> daemonAddresses}) = _$_Settings;

  @override
  bool get isDarkMode;
  @override
  String get languageSelected;
  @override
  String get daemonAddressSelected;
  @override
  List<String> get daemonAddresses;
  @override
  @JsonKey(ignore: true)
  _$$_SettingsCopyWith<_$_Settings> get copyWith =>
      throw _privateConstructorUsedError;
}
