// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'locale_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

LocaleState _$LocaleStateFromJson(Map<String, dynamic> json) {
  return _LocaleState.fromJson(json);
}

/// @nodoc
mixin _$LocaleState {
  @LocaleJsonConverter()
  Locale get locale => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $LocaleStateCopyWith<LocaleState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LocaleStateCopyWith<$Res> {
  factory $LocaleStateCopyWith(
          LocaleState value, $Res Function(LocaleState) then) =
      _$LocaleStateCopyWithImpl<$Res, LocaleState>;
  @useResult
  $Res call({@LocaleJsonConverter() Locale locale});
}

/// @nodoc
class _$LocaleStateCopyWithImpl<$Res, $Val extends LocaleState>
    implements $LocaleStateCopyWith<$Res> {
  _$LocaleStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? locale = null,
  }) {
    return _then(_value.copyWith(
      locale: null == locale
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as Locale,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_LocaleStateCopyWith<$Res>
    implements $LocaleStateCopyWith<$Res> {
  factory _$$_LocaleStateCopyWith(
          _$_LocaleState value, $Res Function(_$_LocaleState) then) =
      __$$_LocaleStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@LocaleJsonConverter() Locale locale});
}

/// @nodoc
class __$$_LocaleStateCopyWithImpl<$Res>
    extends _$LocaleStateCopyWithImpl<$Res, _$_LocaleState>
    implements _$$_LocaleStateCopyWith<$Res> {
  __$$_LocaleStateCopyWithImpl(
      _$_LocaleState _value, $Res Function(_$_LocaleState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? locale = null,
  }) {
    return _then(_$_LocaleState(
      null == locale
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as Locale,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_LocaleState implements _LocaleState {
  const _$_LocaleState(@LocaleJsonConverter() this.locale);

  factory _$_LocaleState.fromJson(Map<String, dynamic> json) =>
      _$$_LocaleStateFromJson(json);

  @override
  @LocaleJsonConverter()
  final Locale locale;

  @override
  String toString() {
    return 'LocaleState(locale: $locale)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_LocaleState &&
            (identical(other.locale, locale) || other.locale == locale));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, locale);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_LocaleStateCopyWith<_$_LocaleState> get copyWith =>
      __$$_LocaleStateCopyWithImpl<_$_LocaleState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_LocaleStateToJson(
      this,
    );
  }
}

abstract class _LocaleState implements LocaleState {
  const factory _LocaleState(@LocaleJsonConverter() final Locale locale) =
      _$_LocaleState;

  factory _LocaleState.fromJson(Map<String, dynamic> json) =
      _$_LocaleState.fromJson;

  @override
  @LocaleJsonConverter()
  Locale get locale;
  @override
  @JsonKey(ignore: true)
  _$$_LocaleStateCopyWith<_$_LocaleState> get copyWith =>
      throw _privateConstructorUsedError;
}
