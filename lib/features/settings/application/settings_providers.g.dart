// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$darkModeHash() => r'fcd18e8bdd68986f625fb08e6d73585e2f8b5122';

/// See also [DarkMode].
@ProviderFor(DarkMode)
final darkModeProvider = AutoDisposeNotifierProvider<DarkMode, bool>.internal(
  DarkMode.new,
  name: r'darkModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$darkModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DarkMode = AutoDisposeNotifier<bool>;
String _$nodeAddressSelectedHash() =>
    r'a57825905444e963075cc6c77dd09b29e287c6e3';

/// See also [NodeAddressSelected].
@ProviderFor(NodeAddressSelected)
final nodeAddressSelectedProvider =
    AutoDisposeNotifierProvider<NodeAddressSelected, String>.internal(
  NodeAddressSelected.new,
  name: r'nodeAddressSelectedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nodeAddressSelectedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NodeAddressSelected = AutoDisposeNotifier<String>;
String _$nodeAddressesHash() => r'eeabfdefa079257d02d21176d3303f17b4744184';

/// See also [NodeAddresses].
@ProviderFor(NodeAddresses)
final nodeAddressesProvider =
    AutoDisposeNotifierProvider<NodeAddresses, List<String>>.internal(
  NodeAddresses.new,
  name: r'nodeAddressesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nodeAddressesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NodeAddresses = AutoDisposeNotifier<List<String>>;
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
