import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/daemon_info_snapshot.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

part 'node_info_provider.g.dart';

@riverpod
Future<DaemonInfoSnapshot?> nodeInfo(Ref ref) async {
  final walletState = ref.watch(
    walletRuntimeProvider.select(
      (state) => (
        selectedNode: state.selectedNode,
        connectionPhase: state.connectionPhase,
        network: state.network,
        topoheight: state.topoheight,
      ),
    ),
  );
  final walletRepository = ref.watch(activeWalletRepositoryProvider);

  if (walletRepository != null &&
      walletState.selectedNode != null &&
      walletState.connectionPhase == WalletConnectionPhase.connected) {
    final info = await walletRepository.getDaemonInfo();
    return projectDaemonInfoSnapshot(info, walletState.network);
  }
  return null;
}

DaemonInfoSnapshot projectDaemonInfoSnapshot(
  wallet_flutter.XelisDaemonInfo info,
  wallet_flutter.XelisNetwork walletNetwork,
) {
  if (info.mempoolSize.isNegative) {
    throw RangeError('mempoolSize cannot be negative: ${info.mempoolSize}');
  }

  return DaemonInfoSnapshot(
    height: formatBigInt(info.height),
    topoHeight: formatBigInt(info.topoheight),
    stableHeight: formatBigInt(info.stableHeight),
    pruned: info.prunedTopoheight != null,
    circulatingSupply: formatXelis(info.circulatingSupply, walletNetwork),
    maximumSupply: formatXelis(info.maximumSupply, walletNetwork),
    emittedSupply: formatXelis(info.emittedSupply, walletNetwork),
    burnSupply: formatXelis(info.burnedSupply, walletNetwork),
    hashRate: formatHashRate(
      difficulty: info.difficulty,
      blockTimeTarget: _checkedPositiveWebSafeInt(
        info.blockTimeTarget,
        'blockTimeTarget',
      ),
    ),
    averageBlockTime: Duration(
      milliseconds: _checkedDurationMilliseconds(info.averageBlockTime),
    ),
    mempoolSize: info.mempoolSize,
    blockReward: formatXelis(info.blockReward, walletNetwork),
    version: info.version,
    network: info.network,
  );
}

final BigInt _maxWebSafeInteger = BigInt.from(9007199254740991);
final BigInt _maxDurationMilliseconds = BigInt.from(9223372036854);

int _checkedPositiveWebSafeInt(BigInt value, String name) {
  if (value <= BigInt.zero || value > _maxWebSafeInteger) {
    throw RangeError('$name must be positive and Web-safe: $value');
  }
  return value.toInt();
}

int _checkedDurationMilliseconds(BigInt value) {
  if (value.isNegative || value > _maxDurationMilliseconds) {
    throw RangeError(
      'averageBlockTime cannot be represented as a Duration: $value',
    );
  }
  return value.toInt();
}
