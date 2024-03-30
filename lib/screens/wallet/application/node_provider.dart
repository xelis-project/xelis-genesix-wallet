import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/domain/daemon_info_snapshot.dart';

part 'node_provider.g.dart';

@riverpod
Future<DaemonInfoSnapshot?> getInfo(GetInfoRef ref) async {
  final repository = ref.watch(
      walletStateProvider.select((value) => value.nativeWalletRepository));
  if (repository != null) {
    var info = await repository.getDaemonInfo();
    return DaemonInfoSnapshot(
      pruned: info.prunedTopoHeight != null ? true : false,
      circulatingSupply: await repository.formatCoin(info.circulatingSupply),
      averageBlockTime: Duration(milliseconds: info.averageBlockTime),
      version: info.version,
      network: info.network,
    );
  }
  return null;
}
