// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$NodeSnapshot {
  String? get endpoint => throw _privateConstructorUsedError;
  String? get version => throw _privateConstructorUsedError;
  int? get topoHeight => throw _privateConstructorUsedError;
  bool? get pruned => throw _privateConstructorUsedError;
  int? get difficulty => throw _privateConstructorUsedError;
  int? get supply => throw _privateConstructorUsedError;
  Network? get network => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $NodeSnapshotCopyWith<NodeSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeSnapshotCopyWith<$Res> {
  factory $NodeSnapshotCopyWith(
          NodeSnapshot value, $Res Function(NodeSnapshot) then) =
      _$NodeSnapshotCopyWithImpl<$Res, NodeSnapshot>;
  @useResult
  $Res call(
      {String? endpoint,
      String? version,
      int? topoHeight,
      bool? pruned,
      int? difficulty,
      int? supply,
      Network? network});
}

/// @nodoc
class _$NodeSnapshotCopyWithImpl<$Res, $Val extends NodeSnapshot>
    implements $NodeSnapshotCopyWith<$Res> {
  _$NodeSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? endpoint = freezed,
    Object? version = freezed,
    Object? topoHeight = freezed,
    Object? pruned = freezed,
    Object? difficulty = freezed,
    Object? supply = freezed,
    Object? network = freezed,
  }) {
    return _then(_value.copyWith(
      endpoint: freezed == endpoint
          ? _value.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      topoHeight: freezed == topoHeight
          ? _value.topoHeight
          : topoHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      pruned: freezed == pruned
          ? _value.pruned
          : pruned // ignore: cast_nullable_to_non_nullable
              as bool?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int?,
      supply: freezed == supply
          ? _value.supply
          : supply // ignore: cast_nullable_to_non_nullable
              as int?,
      network: freezed == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as Network?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NodeSnapshotImplCopyWith<$Res>
    implements $NodeSnapshotCopyWith<$Res> {
  factory _$$NodeSnapshotImplCopyWith(
          _$NodeSnapshotImpl value, $Res Function(_$NodeSnapshotImpl) then) =
      __$$NodeSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? endpoint,
      String? version,
      int? topoHeight,
      bool? pruned,
      int? difficulty,
      int? supply,
      Network? network});
}

/// @nodoc
class __$$NodeSnapshotImplCopyWithImpl<$Res>
    extends _$NodeSnapshotCopyWithImpl<$Res, _$NodeSnapshotImpl>
    implements _$$NodeSnapshotImplCopyWith<$Res> {
  __$$NodeSnapshotImplCopyWithImpl(
      _$NodeSnapshotImpl _value, $Res Function(_$NodeSnapshotImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? endpoint = freezed,
    Object? version = freezed,
    Object? topoHeight = freezed,
    Object? pruned = freezed,
    Object? difficulty = freezed,
    Object? supply = freezed,
    Object? network = freezed,
  }) {
    return _then(_$NodeSnapshotImpl(
      endpoint: freezed == endpoint
          ? _value.endpoint
          : endpoint // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      topoHeight: freezed == topoHeight
          ? _value.topoHeight
          : topoHeight // ignore: cast_nullable_to_non_nullable
              as int?,
      pruned: freezed == pruned
          ? _value.pruned
          : pruned // ignore: cast_nullable_to_non_nullable
              as bool?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as int?,
      supply: freezed == supply
          ? _value.supply
          : supply // ignore: cast_nullable_to_non_nullable
              as int?,
      network: freezed == network
          ? _value.network
          : network // ignore: cast_nullable_to_non_nullable
              as Network?,
    ));
  }
}

/// @nodoc

class _$NodeSnapshotImpl implements _NodeSnapshot {
  const _$NodeSnapshotImpl(
      {this.endpoint,
      this.version,
      this.topoHeight,
      this.pruned,
      this.difficulty,
      this.supply,
      this.network});

  @override
  final String? endpoint;
  @override
  final String? version;
  @override
  final int? topoHeight;
  @override
  final bool? pruned;
  @override
  final int? difficulty;
  @override
  final int? supply;
  @override
  final Network? network;

  @override
  String toString() {
    return 'NodeSnapshot(endpoint: $endpoint, version: $version, topoHeight: $topoHeight, pruned: $pruned, difficulty: $difficulty, supply: $supply, network: $network)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NodeSnapshotImpl &&
            (identical(other.endpoint, endpoint) ||
                other.endpoint == endpoint) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.topoHeight, topoHeight) ||
                other.topoHeight == topoHeight) &&
            (identical(other.pruned, pruned) || other.pruned == pruned) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.supply, supply) || other.supply == supply) &&
            (identical(other.network, network) || other.network == network));
  }

  @override
  int get hashCode => Object.hash(runtimeType, endpoint, version, topoHeight,
      pruned, difficulty, supply, network);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NodeSnapshotImplCopyWith<_$NodeSnapshotImpl> get copyWith =>
      __$$NodeSnapshotImplCopyWithImpl<_$NodeSnapshotImpl>(this, _$identity);
}

abstract class _NodeSnapshot implements NodeSnapshot {
  const factory _NodeSnapshot(
      {final String? endpoint,
      final String? version,
      final int? topoHeight,
      final bool? pruned,
      final int? difficulty,
      final int? supply,
      final Network? network}) = _$NodeSnapshotImpl;

  @override
  String? get endpoint;
  @override
  String? get version;
  @override
  int? get topoHeight;
  @override
  bool? get pruned;
  @override
  int? get difficulty;
  @override
  int? get supply;
  @override
  Network? get network;
  @override
  @JsonKey(ignore: true)
  _$$NodeSnapshotImplCopyWith<_$NodeSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
