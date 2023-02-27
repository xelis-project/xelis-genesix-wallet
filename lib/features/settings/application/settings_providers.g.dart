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
String _$languageSelectedHash() => r'a9f24b75dc52a61db133c9054bec0c13f8065020';

/// See also [LanguageSelected].
@ProviderFor(LanguageSelected)
final languageSelectedProvider =
    AutoDisposeNotifierProvider<LanguageSelected, Languages>.internal(
  LanguageSelected.new,
  name: r'languageSelectedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$languageSelectedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LanguageSelected = AutoDisposeNotifier<Languages>;
String _$daemonAddressSelectedHash() =>
    r'8238f348849f665da4d17ee48fd768df1b69fbbd';

/// See also [DaemonAddressSelected].
@ProviderFor(DaemonAddressSelected)
final daemonAddressSelectedProvider =
    AutoDisposeNotifierProvider<DaemonAddressSelected, String>.internal(
  DaemonAddressSelected.new,
  name: r'daemonAddressSelectedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$daemonAddressSelectedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DaemonAddressSelected = AutoDisposeNotifier<String>;
String _$daemonAddressesHash() => r'9dc6a25f754fbfb77ef86b6bc6391f30cd6b2100';

/// See also [DaemonAddresses].
@ProviderFor(DaemonAddresses)
final daemonAddressesProvider =
    AutoDisposeNotifierProvider<DaemonAddresses, List<String>>.internal(
  DaemonAddresses.new,
  name: r'daemonAddressesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$daemonAddressesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DaemonAddresses = AutoDisposeNotifier<List<String>>;
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
