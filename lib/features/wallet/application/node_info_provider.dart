import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';

part 'node_info_provider.g.dart';

@riverpod
Future<DaemonInfoSnapshot?> nodeInfo(Ref ref) async {
  final walletState = ref.watch(walletStateProvider);
  final repository = walletState.nativeWalletRepository;
  if (repository != null) {
    var info = await repository.getDaemonInfo();

    // keep the state of a successful (only) request
    ref.keepAlive();

    return DaemonInfoSnapshot(
      topoHeight: info.topoHeight,
      pruned: info.prunedTopoHeight != null ? true : false,
      circulatingSupply: formatXelis(info.circulatingSupply),
      averageBlockTime: Duration(milliseconds: info.averageBlockTime),
      mempoolSize: info.mempoolSize,
      blockReward: formatXelis(info.blockReward),
      version: info.version,
      network: info.network,
    );
  }
  return null;
}
