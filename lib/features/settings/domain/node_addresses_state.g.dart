// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_addresses_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NodeAddressesStateImpl _$$NodeAddressesStateImplFromJson(
        Map<String, dynamic> json) =>
    _$NodeAddressesStateImpl(
      favorite: json['favorite'] as String,
      nodeAddresses: (json['nodeAddresses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$NodeAddressesStateImplToJson(
        _$NodeAddressesStateImpl instance) =>
    <String, dynamic>{
      'favorite': instance.favorite,
      'nodeAddresses': instance.nodeAddresses,
    };
