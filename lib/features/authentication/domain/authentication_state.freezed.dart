// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authentication_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$AuthenticationState {
  int? get walletId => throw _privateConstructorUsedError;
  List<int>? get secretKey => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int walletId, List<int> secretKey) signedIn,
    required TResult Function(int? walletId, List<int>? secretKey) signedOut,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int walletId, List<int> secretKey)? signedIn,
    TResult? Function(int? walletId, List<int>? secretKey)? signedOut,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int walletId, List<int> secretKey)? signedIn,
    TResult Function(int? walletId, List<int>? secretKey)? signedOut,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignedIn value) signedIn,
    required TResult Function(SignedOut value) signedOut,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignedIn value)? signedIn,
    TResult? Function(SignedOut value)? signedOut,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignedIn value)? signedIn,
    TResult Function(SignedOut value)? signedOut,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AuthenticationStateCopyWith<AuthenticationState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthenticationStateCopyWith<$Res> {
  factory $AuthenticationStateCopyWith(
          AuthenticationState value, $Res Function(AuthenticationState) then) =
      _$AuthenticationStateCopyWithImpl<$Res, AuthenticationState>;
  @useResult
  $Res call({int walletId, List<int> secretKey});
}

/// @nodoc
class _$AuthenticationStateCopyWithImpl<$Res, $Val extends AuthenticationState>
    implements $AuthenticationStateCopyWith<$Res> {
  _$AuthenticationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walletId = null,
    Object? secretKey = null,
  }) {
    return _then(_value.copyWith(
      walletId: null == walletId
          ? _value.walletId!
          : walletId // ignore: cast_nullable_to_non_nullable
              as int,
      secretKey: null == secretKey
          ? _value.secretKey!
          : secretKey // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SignedInImplCopyWith<$Res>
    implements $AuthenticationStateCopyWith<$Res> {
  factory _$$SignedInImplCopyWith(
          _$SignedInImpl value, $Res Function(_$SignedInImpl) then) =
      __$$SignedInImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int walletId, List<int> secretKey});
}

/// @nodoc
class __$$SignedInImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$SignedInImpl>
    implements _$$SignedInImplCopyWith<$Res> {
  __$$SignedInImplCopyWithImpl(
      _$SignedInImpl _value, $Res Function(_$SignedInImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walletId = null,
    Object? secretKey = null,
  }) {
    return _then(_$SignedInImpl(
      walletId: null == walletId
          ? _value.walletId
          : walletId // ignore: cast_nullable_to_non_nullable
              as int,
      secretKey: null == secretKey
          ? _value._secretKey
          : secretKey // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc

class _$SignedInImpl extends SignedIn {
  const _$SignedInImpl(
      {required this.walletId, required final List<int> secretKey})
      : _secretKey = secretKey,
        super._();

  @override
  final int walletId;
  final List<int> _secretKey;
  @override
  List<int> get secretKey {
    if (_secretKey is EqualUnmodifiableListView) return _secretKey;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_secretKey);
  }

  @override
  String toString() {
    return 'AuthenticationState.signedIn(walletId: $walletId, secretKey: $secretKey)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignedInImpl &&
            (identical(other.walletId, walletId) ||
                other.walletId == walletId) &&
            const DeepCollectionEquality()
                .equals(other._secretKey, _secretKey));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, walletId, const DeepCollectionEquality().hash(_secretKey));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SignedInImplCopyWith<_$SignedInImpl> get copyWith =>
      __$$SignedInImplCopyWithImpl<_$SignedInImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int walletId, List<int> secretKey) signedIn,
    required TResult Function(int? walletId, List<int>? secretKey) signedOut,
  }) {
    return signedIn(walletId, secretKey);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int walletId, List<int> secretKey)? signedIn,
    TResult? Function(int? walletId, List<int>? secretKey)? signedOut,
  }) {
    return signedIn?.call(walletId, secretKey);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int walletId, List<int> secretKey)? signedIn,
    TResult Function(int? walletId, List<int>? secretKey)? signedOut,
    required TResult orElse(),
  }) {
    if (signedIn != null) {
      return signedIn(walletId, secretKey);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignedIn value) signedIn,
    required TResult Function(SignedOut value) signedOut,
  }) {
    return signedIn(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignedIn value)? signedIn,
    TResult? Function(SignedOut value)? signedOut,
  }) {
    return signedIn?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignedIn value)? signedIn,
    TResult Function(SignedOut value)? signedOut,
    required TResult orElse(),
  }) {
    if (signedIn != null) {
      return signedIn(this);
    }
    return orElse();
  }
}

abstract class SignedIn extends AuthenticationState {
  const factory SignedIn(
      {required final int walletId,
      required final List<int> secretKey}) = _$SignedInImpl;
  const SignedIn._() : super._();

  @override
  int get walletId;
  @override
  List<int> get secretKey;
  @override
  @JsonKey(ignore: true)
  _$$SignedInImplCopyWith<_$SignedInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SignedOutImplCopyWith<$Res>
    implements $AuthenticationStateCopyWith<$Res> {
  factory _$$SignedOutImplCopyWith(
          _$SignedOutImpl value, $Res Function(_$SignedOutImpl) then) =
      __$$SignedOutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int? walletId, List<int>? secretKey});
}

/// @nodoc
class __$$SignedOutImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$SignedOutImpl>
    implements _$$SignedOutImplCopyWith<$Res> {
  __$$SignedOutImplCopyWithImpl(
      _$SignedOutImpl _value, $Res Function(_$SignedOutImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walletId = freezed,
    Object? secretKey = freezed,
  }) {
    return _then(_$SignedOutImpl(
      walletId: freezed == walletId
          ? _value.walletId
          : walletId // ignore: cast_nullable_to_non_nullable
              as int?,
      secretKey: freezed == secretKey
          ? _value._secretKey
          : secretKey // ignore: cast_nullable_to_non_nullable
              as List<int>?,
    ));
  }
}

/// @nodoc

class _$SignedOutImpl extends SignedOut {
  const _$SignedOutImpl({this.walletId, final List<int>? secretKey})
      : _secretKey = secretKey,
        super._();

  @override
  final int? walletId;
  final List<int>? _secretKey;
  @override
  List<int>? get secretKey {
    final value = _secretKey;
    if (value == null) return null;
    if (_secretKey is EqualUnmodifiableListView) return _secretKey;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'AuthenticationState.signedOut(walletId: $walletId, secretKey: $secretKey)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignedOutImpl &&
            (identical(other.walletId, walletId) ||
                other.walletId == walletId) &&
            const DeepCollectionEquality()
                .equals(other._secretKey, _secretKey));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, walletId, const DeepCollectionEquality().hash(_secretKey));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SignedOutImplCopyWith<_$SignedOutImpl> get copyWith =>
      __$$SignedOutImplCopyWithImpl<_$SignedOutImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int walletId, List<int> secretKey) signedIn,
    required TResult Function(int? walletId, List<int>? secretKey) signedOut,
  }) {
    return signedOut(walletId, secretKey);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int walletId, List<int> secretKey)? signedIn,
    TResult? Function(int? walletId, List<int>? secretKey)? signedOut,
  }) {
    return signedOut?.call(walletId, secretKey);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int walletId, List<int> secretKey)? signedIn,
    TResult Function(int? walletId, List<int>? secretKey)? signedOut,
    required TResult orElse(),
  }) {
    if (signedOut != null) {
      return signedOut(walletId, secretKey);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SignedIn value) signedIn,
    required TResult Function(SignedOut value) signedOut,
  }) {
    return signedOut(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SignedIn value)? signedIn,
    TResult? Function(SignedOut value)? signedOut,
  }) {
    return signedOut?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SignedIn value)? signedIn,
    TResult Function(SignedOut value)? signedOut,
    required TResult orElse(),
  }) {
    if (signedOut != null) {
      return signedOut(this);
    }
    return orElse();
  }
}

abstract class SignedOut extends AuthenticationState {
  const factory SignedOut({final int? walletId, final List<int>? secretKey}) =
      _$SignedOutImpl;
  const SignedOut._() : super._();

  @override
  int? get walletId;
  @override
  List<int>? get secretKey;
  @override
  @JsonKey(ignore: true)
  _$$SignedOutImplCopyWith<_$SignedOutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
