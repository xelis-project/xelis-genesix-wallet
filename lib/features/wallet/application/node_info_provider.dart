import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';

part 'node_info_provider.g.dart';

@riverpod
Future<DaemonInfoSnapshot?> nodeInfo(Ref ref) async {
  final walletState = ref.watch(walletRuntimeProvider);
  final walletRepository = ref.watch(activeWalletRepositoryProvider);

  if (walletRepository != null &&
      walletState.selectedNode != null &&
      walletState.connectionPhase == WalletConnectionPhase.connected) {
    var info = await walletRepository.getDaemonInfo();

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
