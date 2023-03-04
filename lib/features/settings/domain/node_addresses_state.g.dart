// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_addresses_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_NodeAddressesState _$$_NodeAddressesStateFromJson(
        Map<String, dynamic> json) =>
    _$_NodeAddressesState(
      favorite: json['favorite'] as String,
      nodeAddresses: (json['nodeAddresses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$_NodeAddressesStateToJson(
        _$_NodeAddressesState instance) =>
    <String, dynamic>{
      'favorite': instance.favorite,
      'nodeAddresses': instance.nodeAddresses,
    };
