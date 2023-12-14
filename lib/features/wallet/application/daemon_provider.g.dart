// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daemon_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$daemonClientRepositoryPodHash() =>
    r'1dba10de17aafdb6e04f724c513d28b85d42dbe4';

/// See also [daemonClientRepositoryPod].
@ProviderFor(daemonClientRepositoryPod)
final daemonClientRepositoryPodProvider =
    AutoDisposeProvider<DaemonClientRepository>.internal(
  daemonClientRepositoryPod,
  name: r'daemonClientRepositoryPodProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$daemonClientRepositoryPodHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DaemonClientRepositoryPodRef
    = AutoDisposeProviderRef<DaemonClientRepository>;
String _$daemonStateHash() => r'dda7d844838ad7957b22a4ff8efce9d338df1c46';

/// See also [daemonState].
@ProviderFor(daemonState)
final daemonStateProvider = AutoDisposeStreamProvider<String>.internal(
  daemonState,
  name: r'daemonStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$daemonStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DaemonStateRef = AutoDisposeStreamProviderRef<String>;
String _$daemonInfoHash() => r'f8e1e4962f1ebaeaf5eac18421aee5b9b0f8cdf0';

/// See also [daemonInfo].
@ProviderFor(daemonInfo)
final daemonInfoProvider = AutoDisposeFutureProvider<GetInfoResult>.internal(
  daemonInfo,
  name: r'daemonInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$daemonInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DaemonInfoRef = AutoDisposeFutureProviderRef<GetInfoResult>;
String _$networkTopoHeightHash() => r'aa18df9e13ac7013c85f54040a983f17342c240a';

/// See also [networkTopoHeight].
@ProviderFor(networkTopoHeight)
final networkTopoHeightProvider = AutoDisposeFutureProvider<int>.internal(
  networkTopoHeight,
  name: r'networkTopoHeightProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkTopoHeightHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetworkTopoHeightRef = AutoDisposeFutureProviderRef<int>;
String _$timerHash() => r'2d3051684274080b6b057a484966195a641951bb';

/// See also [timer].
@ProviderFor(timer)
final timerProvider = AutoDisposeProvider<void>.internal(
  timer,
  name: r'timerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$timerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TimerRef = AutoDisposeProviderRef<void>;
String _$networkHashrateHash() => r'015f7504d25fb8620251a4d8816584a543361df7';

/// See also [networkHashrate].
@ProviderFor(networkHashrate)
final networkHashrateProvider = AutoDisposeFutureProvider<int>.internal(
  networkHashrate,
  name: r'networkHashrateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkHashrateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetworkHashrateRef = AutoDisposeFutureProviderRef<int>;
String _$networkNativeSupplyHash() =>
    r'9941a21004c0851c81c77e004dfb5d940fd4bafb';

/// See also [networkNativeSupply].
@ProviderFor(networkNativeSupply)
final networkNativeSupplyProvider = AutoDisposeFutureProvider<int>.internal(
  networkNativeSupply,
  name: r'networkNativeSupplyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkNativeSupplyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetworkNativeSupplyRef = AutoDisposeFutureProviderRef<int>;
String _$networkMempoolHash() => r'95f8a5c7299f05a97f3b82b3fc1c25ad79e886ef';

/// See also [networkMempool].
@ProviderFor(networkMempool)
final networkMempoolProvider = AutoDisposeFutureProvider<int>.internal(
  networkMempool,
  name: r'networkMempoolProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkMempoolHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef NetworkMempoolRef = AutoDisposeFutureProviderRef<int>;
String _$daemonVersionHash() => r'706c8832a64b17415ebdce31693e7e2fda658265';

/// See also [daemonVersion].
@ProviderFor(daemonVersion)
final daemonVersionProvider = AutoDisposeFutureProvider<String>.internal(
  daemonVersion,
  name: r'daemonVersionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$daemonVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DaemonVersionRef = AutoDisposeFutureProviderRef<String>;
String _$daemonNetworkHash() => r'3e9a188fd23a9b7cacde03bc4558b21435d89bcc';

/// See also [daemonNetwork].
@ProviderFor(daemonNetwork)
final daemonNetworkProvider = AutoDisposeFutureProvider<String>.internal(
  daemonNetwork,
  name: r'daemonNetworkProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$daemonNetworkHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DaemonNetworkRef = AutoDisposeFutureProviderRef<String>;
String _$nodeInfoHash() => r'02c4a548b7f724f0056433e8901859e03853295c';

/// See also [NodeInfo].
@ProviderFor(NodeInfo)
final nodeInfoProvider =
    AutoDisposeAsyncNotifierProvider<NodeInfo, NodeSnapshot>.internal(
  NodeInfo.new,
  name: r'nodeInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$nodeInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NodeInfo = AutoDisposeAsyncNotifier<NodeSnapshot>;
String _$lastBlockTimerHash() => r'5e63cbfafd60332d133c3885294f610312709945';

/// See also [LastBlockTimer].
@ProviderFor(LastBlockTimer)
final lastBlockTimerProvider =
    AutoDisposeNotifierProvider<LastBlockTimer, int>.internal(
  LastBlockTimer.new,
  name: r'lastBlockTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lastBlockTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LastBlockTimer = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
