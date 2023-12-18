// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$openWalletDataHash() => r'8422320406b17556fb6d3413a6366a9658965f48';

/// See also [openWalletData].
@ProviderFor(openWalletData)
final openWalletDataProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  openWalletData,
  name: r'openWalletDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$openWalletDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OpenWalletDataRef = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$authenticationHash() => r'bbb8da046d6966fdf40802361bf5dc3095a74f38';

/// See also [Authentication].
@ProviderFor(Authentication)
final authenticationProvider =
    AutoDisposeNotifierProvider<Authentication, AuthenticationState>.internal(
  Authentication.new,
  name: r'authenticationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authenticationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Authentication = AutoDisposeNotifier<AuthenticationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
