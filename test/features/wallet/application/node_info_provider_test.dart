import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/node_info_provider.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('keeps daemon mempool u64 values lossless', () {
    final maximumU64 = (BigInt.one << 64) - BigInt.one;

    final snapshot = projectDaemonInfoSnapshot(
      _daemonInfo(mempoolSize: maximumU64),
      XelisNetwork.mainnet,
    );

    expect(snapshot.mempoolSize, maximumU64);
  });

  test('rejects daemon values that cannot be projected safely', () {
    final aboveWebSafeInteger = BigInt.from(9007199254740992);
    expect(
      () => projectDaemonInfoSnapshot(
        _daemonInfo(blockTimeTarget: aboveWebSafeInteger),
        XelisNetwork.mainnet,
      ),
      throwsRangeError,
    );
    expect(
      () => projectDaemonInfoSnapshot(
        _daemonInfo(averageBlockTime: BigInt.from(9223372036855)),
        XelisNetwork.mainnet,
      ),
      throwsRangeError,
    );
    expect(
      () => projectDaemonInfoSnapshot(
        _daemonInfo(mempoolSize: BigInt.from(-1)),
        XelisNetwork.mainnet,
      ),
      throwsRangeError,
    );
  });
}

XelisDaemonInfo _daemonInfo({
  BigInt? mempoolSize,
  BigInt? blockTimeTarget,
  BigInt? averageBlockTime,
}) => XelisDaemonInfo(
  height: BigInt.zero,
  topoheight: BigInt.zero,
  stableHeight: BigInt.zero,
  stableTopoheight: BigInt.zero,
  prunedTopoheight: null,
  topBlockHash: '00',
  circulatingSupply: BigInt.zero,
  burnedSupply: BigInt.zero,
  emittedSupply: BigInt.zero,
  maximumSupply: BigInt.zero,
  difficulty: '1',
  blockTimeTarget: blockTimeTarget ?? BigInt.one,
  averageBlockTime: averageBlockTime ?? BigInt.one,
  blockReward: BigInt.zero,
  devReward: BigInt.zero,
  minerReward: BigInt.zero,
  mempoolSize: mempoolSize ?? BigInt.zero,
  version: 'test',
  network: XelisNetwork.mainnet,
  blockVersion: 0,
);
