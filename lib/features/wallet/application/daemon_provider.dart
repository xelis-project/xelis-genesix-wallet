import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/node_addresses_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/node_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

part 'daemon_provider.g.dart';

@riverpod
DaemonClientRepository daemonClientRepositoryPod(
  DaemonClientRepositoryPodRef ref,
) {
  final nodeAddresses = ref.watch(nodeAddressesProvider);
  final daemonClientRepository = DaemonClientRepository(
    endPoint: nodeAddresses.favorite,
    // secureWebSocket: false,
    // logger: logger,
    timeout: 5000,
  )..connect();

  ref.onDispose(daemonClientRepository.disconnect);

  return daemonClientRepository;
}

@riverpod
Stream<String> daemonState(DaemonStateRef ref) async* {
  final daemonClientRepository = ref.watch(daemonClientRepositoryPodProvider);
  await for (final currentState in daemonClientRepository.state) {
    yield currentState.name;
  }
}

@riverpod
class NodeInfo extends _$NodeInfo {
  @override
  Future<NodeSnapshot> build() async {
    final res = await ref.watch(daemonInfoProvider.future);
    final currentEndpoint = ref.watch(
      nodeAddressesProvider.select(
        (state) => state.favorite,
      ),
    );
    return NodeSnapshot(
        endpoint: currentEndpoint,
        version: res.version,
        topoHeight: res.topoHeight,
        pruned: res.prunedTopoHeight == null ? false : true,
        difficulty: res.difficulty,
        supply: res.circulatingSupply,
        network: res.network);
  }

  Future<void> updateOnNewBlock(
      int? newTopoHeight, int newDifficulty, int? newSupply) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(
        topoHeight: newTopoHeight,
        difficulty: newDifficulty,
        supply: newSupply));
  }

  Future<void> setEndpoint(String value) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(endpoint: value));
  }

  Future<void> setVersion(String value) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(version: value));
  }

  Future<void> setTopoHeight(int value) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(topoHeight: value));
  }

  Future<void> setPrunedHeight(bool value) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(pruned: value));
  }

  Future<void> setDifficulty(int value) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(difficulty: value));
  }

  Future<void> setSupply(int value) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(supply: value));
  }

  Future<void> setNetwork(Network value) async {
    final previousState = await future;
    state = AsyncData(previousState.copyWith(network: value));
  }
}

@riverpod
Future<GetInfoResult> daemonInfo(DaemonInfoRef ref) async {
  final daemonClientRepository = ref.watch(daemonClientRepositoryPodProvider);
  final info = await daemonClientRepository.getInfo();
  return info;
}

@riverpod
Future<int> networkTopoHeight(NetworkTopoHeightRef ref) async {
  return ref.watch(daemonInfoProvider.selectAsync((info) => info.topoHeight));
}

@riverpod
void timer(TimerRef ref) {
  final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    ref.read(lastBlockTimerProvider.notifier).increment();
  });
  ref.onDispose(timer.cancel);
}

@riverpod
class LastBlockTimer extends _$LastBlockTimer {
  @override
  int build() {
    ref.watch(timerProvider);
    return 0;
  }

  void increment() {
    state++;
  }
}

@riverpod
Future<int> networkHashrate(NetworkHashrateRef ref) async {
  return ref.watch(daemonInfoProvider.selectAsync((info) => info.difficulty));
}

@riverpod
Future<int> networkNativeSupply(NetworkNativeSupplyRef ref) async {
  return ref
      .watch(daemonInfoProvider.selectAsync((info) => info.circulatingSupply));
}

@riverpod
Future<int> networkMempool(NetworkMempoolRef ref) async {
  return ref.watch(daemonInfoProvider.selectAsync((info) => info.mempoolSize));
}

@riverpod
Future<String> daemonVersion(DaemonVersionRef ref) async {
  return ref.watch(daemonInfoProvider.selectAsync((info) => info.version));
}

@riverpod
Future<String> daemonNetwork(DaemonNetworkRef ref) async {
  return ref.watch(daemonInfoProvider.selectAsync((info) => info.network.name));
}
