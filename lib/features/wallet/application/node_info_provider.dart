import 'package:genesix/shared/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';

part 'node_info_provider.g.dart';

@riverpod
Future<DaemonInfoSnapshot?> nodeInfo(Ref ref) async {
  final walletState = ref.watch(walletStateProvider);
  final walletRepository = walletState.nativeWalletRepository;
  if (walletRepository != null && walletState.isOnline) {
    var info = await walletRepository.getDaemonInfo();

    // keep the state of a successful (only) request
    ref.keepAlive();

    return DaemonInfoSnapshot(
      height: NumberFormat().format(info.height),
      topoHeight: NumberFormat().format(info.topoHeight),
      pruned: info.prunedTopoHeight != null ? true : false,
      circulatingSupply: formatXelis(
        info.circulatingSupply,
        walletState.network,
      ),
      maximumSupply: formatXelis(info.maximumSupply, walletState.network),
      emittedSupply: formatXelis(info.emittedSupply, walletState.network),
      burnSupply: formatXelis(info.burnedSupply, walletState.network),
      hashRate: formatHashRate(
        difficulty: info.difficulty,
        blockTimeTarget: info.blockTimeTarget,
      ),
      averageBlockTime: Duration(milliseconds: info.averageBlockTime),
      mempoolSize: info.mempoolSize,
      blockReward: formatXelis(info.blockReward, walletState.network),
      version: info.version,
      network: info.network,
    );
  }
  return null;
}
