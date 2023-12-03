// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$walletServicePodHash() => r'1f19749cc97743ba04ba2f1405011d3a6aec4db2';

/// See also [walletServicePod].
@ProviderFor(walletServicePod)
final walletServicePodProvider =
    AutoDisposeFutureProvider<WalletService>.internal(
  walletServicePod,
  name: r'walletServicePodProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletServicePodHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletServicePodRef = AutoDisposeFutureProviderRef<WalletService>;
String _$storageManagerPodHash() => r'53b7ad5cfe80d8b9063fd902ca40fc6ce204b712';

/// See also [storageManagerPod].
@ProviderFor(storageManagerPod)
final storageManagerPodProvider =
    AutoDisposeFutureProvider<StorageManager>.internal(
  storageManagerPod,
  name: r'storageManagerPodProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storageManagerPodHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StorageManagerPodRef = AutoDisposeFutureProviderRef<StorageManager>;
String _$walletNameHash() => r'a9bd61793b999ae83ba79f75f5409ac961d72d79';

/// See also [walletName].
@ProviderFor(walletName)
final walletNameProvider = AutoDisposeStreamProvider<String>.internal(
  walletName,
  name: r'walletNameProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$walletNameHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletNameRef = AutoDisposeStreamProviderRef<String>;
String _$walletCurrentTopoHeightHash() =>
    r'cba0792278591147d8becd2a8c50f41f46cdb3bd';

/// See also [walletCurrentTopoHeight].
@ProviderFor(walletCurrentTopoHeight)
final walletCurrentTopoHeightProvider = AutoDisposeStreamProvider<int>.internal(
  walletCurrentTopoHeight,
  name: r'walletCurrentTopoHeightProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletCurrentTopoHeightHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletCurrentTopoHeightRef = AutoDisposeStreamProviderRef<int>;
String _$walletAddressHash() => r'f1ef61924f23b39e818c2339bc3567603e04d708';

/// See also [walletAddress].
@ProviderFor(walletAddress)
final walletAddressProvider = AutoDisposeStreamProvider<String>.internal(
  walletAddress,
  name: r'walletAddressProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletAddressHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletAddressRef = AutoDisposeStreamProviderRef<String>;
String _$walletXelisBalanceHash() =>
    r'8bccce456b8727949415f05f5c1e072a2ecdcc12';

/// See also [walletXelisBalance].
@ProviderFor(walletXelisBalance)
final walletXelisBalanceProvider =
    AutoDisposeStreamProvider<VersionedBalance>.internal(
  walletXelisBalance,
  name: r'walletXelisBalanceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletXelisBalanceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletXelisBalanceRef = AutoDisposeStreamProviderRef<VersionedBalance>;
String _$walletHistoryHash() => r'19b8b20ff9331358ebaab4ca1c8048ccdf6d5a84';

/// See also [walletHistory].
@ProviderFor(walletHistory)
final walletHistoryProvider =
    AutoDisposeStreamProvider<List<TransactionEntry>>.internal(
  walletHistory,
  name: r'walletHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$walletHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletHistoryRef = AutoDisposeStreamProviderRef<List<TransactionEntry>>;
String _$walletAssetsHash() => r'5a4a7f8b13ae6c1bdd487e07d4b7ba37f6f7819f';

/// See also [walletAssets].
@ProviderFor(walletAssets)
final walletAssetsProvider =
    AutoDisposeStreamProvider<List<AssetEntry>>.internal(
  walletAssets,
  name: r'walletAssetsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$walletAssetsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletAssetsRef = AutoDisposeStreamProviderRef<List<AssetEntry>>;
String _$walletAssetLastBalanceHash() =>
    r'e658e7fe6850db9acfc34ec4476b60340d81964d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [walletAssetLastBalance].
@ProviderFor(walletAssetLastBalance)
const walletAssetLastBalanceProvider = WalletAssetLastBalanceFamily();

/// See also [walletAssetLastBalance].
class WalletAssetLastBalanceFamily
    extends Family<AsyncValue<VersionedBalance>> {
  /// See also [walletAssetLastBalance].
  const WalletAssetLastBalanceFamily();

  /// See also [walletAssetLastBalance].
  WalletAssetLastBalanceProvider call({
    required String hash,
  }) {
    return WalletAssetLastBalanceProvider(
      hash: hash,
    );
  }

  @override
  WalletAssetLastBalanceProvider getProviderOverride(
    covariant WalletAssetLastBalanceProvider provider,
  ) {
    return call(
      hash: provider.hash,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'walletAssetLastBalanceProvider';
}

/// See also [walletAssetLastBalance].
class WalletAssetLastBalanceProvider
    extends AutoDisposeStreamProvider<VersionedBalance> {
  /// See also [walletAssetLastBalance].
  WalletAssetLastBalanceProvider({
    required String hash,
  }) : this._internal(
          (ref) => walletAssetLastBalance(
            ref as WalletAssetLastBalanceRef,
            hash: hash,
          ),
          from: walletAssetLastBalanceProvider,
          name: r'walletAssetLastBalanceProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$walletAssetLastBalanceHash,
          dependencies: WalletAssetLastBalanceFamily._dependencies,
          allTransitiveDependencies:
              WalletAssetLastBalanceFamily._allTransitiveDependencies,
          hash: hash,
        );

  WalletAssetLastBalanceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.hash,
  }) : super.internal();

  final String hash;

  @override
  Override overrideWith(
    Stream<VersionedBalance> Function(WalletAssetLastBalanceRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WalletAssetLastBalanceProvider._internal(
        (ref) => create(ref as WalletAssetLastBalanceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        hash: hash,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<VersionedBalance> createElement() {
    return _WalletAssetLastBalanceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletAssetLastBalanceProvider && other.hash == hash;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, hash.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WalletAssetLastBalanceRef
    on AutoDisposeStreamProviderRef<VersionedBalance> {
  /// The parameter `hash` of this provider.
  String get hash;
}

class _WalletAssetLastBalanceProviderElement
    extends AutoDisposeStreamProviderElement<VersionedBalance>
    with WalletAssetLastBalanceRef {
  _WalletAssetLastBalanceProviderElement(super.provider);

  @override
  String get hash => (origin as WalletAssetLastBalanceProvider).hash;
}

String _$walletSeedHash() => r'21e0ec3ee23bbc2f540cfcda004bcf07c0d56f97';

/// See also [walletSeed].
@ProviderFor(walletSeed)
final walletSeedProvider = AutoDisposeFutureProvider<String>.internal(
  walletSeed,
  name: r'walletSeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$walletSeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WalletSeedRef = AutoDisposeFutureProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
