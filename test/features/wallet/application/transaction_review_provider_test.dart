import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('replacing the wallet session clears the prepared capability', () {
    final repositoryA = _FakeRepository('a');
    final repositoryB = _FakeRepository('b');
    final container = ProviderContainer(
      overrides: [walletRuntimeProvider.overrideWithValue(_runtime)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      transactionReviewProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'a', repository: repositoryA));
    final prepared = XelisWalletPreparedTransaction(
      hash: 'prepared-hash',
      feeAtomic: BigInt.one,
      details: XelisWalletPreparedBurn(
        asset: 'asset-hash',
        amountAtomic: BigInt.one,
      ),
    );
    container
        .read(transactionReviewProvider.notifier)
        .setPreparedBurnTransaction(prepared, sessionIdentity: repositoryA);

    expect(container.read(transactionReviewProvider), isA<BurnTransaction>());

    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'b', repository: repositoryB));

    expect(container.read(transactionReviewProvider), isA<Initial>());
  });

  test('rejects a prepared capability owned by an inactive session', () {
    final repositoryA = _FakeRepository('a');
    final repositoryB = _FakeRepository('b');
    final container = ProviderContainer(
      overrides: [walletRuntimeProvider.overrideWithValue(_runtime)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      transactionReviewProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'b', repository: repositoryB));
    final prepared = XelisWalletPreparedTransaction(
      hash: 'stale-prepared-hash',
      feeAtomic: BigInt.one,
      details: XelisWalletPreparedBurn(
        asset: 'asset-hash',
        amountAtomic: BigInt.one,
      ),
    );

    expect(
      () => container
          .read(transactionReviewProvider.notifier)
          .setPreparedBurnTransaction(prepared, sessionIdentity: repositoryA),
      throwsStateError,
    );
    expect(container.read(transactionReviewProvider), isA<Initial>());
  });
}

final _runtime = WalletRuntimeState(
  network: XelisNetwork.mainnet,
  topoheight: BigInt.zero,
  xelisBalance: BigInt.zero,
  trackedBalances: LinkedHashMap(),
  knownAssets: LinkedHashMap(),
);

final class _FakeRepository implements NativeWalletRepository {
  _FakeRepository(this.label);

  final String label;

  @override
  String get address => 'wallet-$label';

  @override
  XelisNetwork get network => XelisNetwork.mainnet;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
