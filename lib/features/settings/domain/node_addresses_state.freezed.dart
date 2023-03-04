// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_addresses_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

NodeAddressesState _$NodeAddressesStateFromJson(Map<String, dynamic> json) {
  return _NodeAddressesState.fromJson(json);
}

/// @nodoc
mixin _$NodeAddressesState {
  String get favorite => throw _privateConstructorUsedError;
  List<String> get nodeAddresses => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NodeAddressesStateCopyWith<NodeAddressesState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeAddressesStateCopyWith<$Res> {
  factory $NodeAddressesStateCopyWith(
          NodeAddressesState value, $Res Function(NodeAddressesState) then) =
      _$NodeAddressesStateCopyWithImpl<$Res, NodeAddressesState>;
  @useResult
  $Res call({String favorite, List<String> nodeAddresses});
}

/// @nodoc
class _$NodeAddressesStateCopyWithImpl<$Res, $Val extends NodeAddressesState>
    implements $NodeAddressesStateCopyWith<$Res> {
  _$NodeAddressesStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? favorite = null,
    Object? nodeAddresses = null,
  }) {
    return _then(_value.copyWith(
      favorite: null == favorite
          ? _value.favorite
          : favorite // ignore: cast_nullable_to_non_nullable
              as String,
      nodeAddresses: null == nodeAddresses
          ? _value.nodeAddresses
          : nodeAddresses // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_NodeAddressesStateCopyWith<$Res>
    implements $NodeAddressesStateCopyWith<$Res> {
  factory _$$_NodeAddressesStateCopyWith(_$_NodeAddressesState value,
          $Res Function(_$_NodeAddressesState) then) =
      __$$_NodeAddressesStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String favorite, List<String> nodeAddresses});
}

/// @nodoc
class __$$_NodeAddressesStateCopyWithImpl<$Res>
    extends _$NodeAddressesStateCopyWithImpl<$Res, _$_NodeAddressesState>
    implements _$$_NodeAddressesStateCopyWith<$Res> {
  __$$_NodeAddressesStateCopyWithImpl(
      _$_NodeAddressesState _value, $Res Function(_$_NodeAddressesState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? favorite = null,
    Object? nodeAddresses = null,
  }) {
    return _then(_$_NodeAddressesState(
      favorite: null == favorite
          ? _value.favorite
          : favorite // ignore: cast_nullable_to_non_nullable
              as String,
      nodeAddresses: null == nodeAddresses
          ? _value._nodeAddresses
          : nodeAddresses // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_NodeAddressesState implements _NodeAddressesState {
  const _$_NodeAddressesState(
      {required this.favorite, final List<String> nodeAddresses = const []})
      : _nodeAddresses = nodeAddresses;

  factory _$_NodeAddressesState.fromJson(Map<String, dynamic> json) =>
      _$$_NodeAddressesStateFromJson(json);

  @override
  final String favorite;
  final List<String> _nodeAddresses;
  @override
  @JsonKey()
  List<String> get nodeAddresses {
    if (_nodeAddresses is EqualUnmodifiableListView) return _nodeAddresses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nodeAddresses);
  }

  @override
  String toString() {
    return 'NodeAddressesState(favorite: $favorite, nodeAddresses: $nodeAddresses)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_NodeAddressesState &&
            (identical(other.favorite, favorite) ||
                other.favorite == favorite) &&
            const DeepCollectionEquality()
                .equals(other._nodeAddresses, _nodeAddresses));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, favorite,
      const DeepCollectionEquality().hash(_nodeAddresses));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_NodeAddressesStateCopyWith<_$_NodeAddressesState> get copyWith =>
      __$$_NodeAddressesStateCopyWithImpl<_$_NodeAddressesState>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_NodeAddressesStateToJson(
      this,
    );
  }
}

abstract class _NodeAddressesState implements NodeAddressesState {
  const factory _NodeAddressesState(
      {required final String favorite,
      final List<String> nodeAddresses}) = _$_NodeAddressesState;

  factory _NodeAddressesState.fromJson(Map<String, dynamic> json) =
      _$_NodeAddressesState.fromJson;

  @override
  String get favorite;
  @override
  List<String> get nodeAddresses;
  @override
  @JsonKey(ignore: true)
  _$$_NodeAddressesStateCopyWith<_$_NodeAddressesState> get copyWith =>
      throw _privateConstructorUsedError;
}
