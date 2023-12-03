import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/settings/application/node_addresses_state_provider.dart';
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
