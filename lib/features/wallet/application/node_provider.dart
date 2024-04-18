import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';

part 'node_provider.g.dart';

@riverpod
Future<DaemonInfoSnapshot?> getInfo(GetInfoRef ref) async {
  final walletState = ref.watch(walletStateProvider);
  final repository = walletState.nativeWalletRepository;
  if (repository != null) {
    var info = await repository.getDaemonInfo();

    // keep the state of a successful (only) request
    ref.keepAlive();

    return DaemonInfoSnapshot(
      topoHeight: info.topoHeight,
      pruned: info.prunedTopoHeight != null ? true : false,
      circulatingSupply: await repository.formatCoin(info.circulatingSupply),
      averageBlockTime: Duration(milliseconds: info.averageBlockTime),
      version: info.version,
      network: info.network,
    );
  }
  return null;
}
