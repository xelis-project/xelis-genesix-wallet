import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallets_provider.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('same wallet name on another network is not the target session', () {
    final mainnet = WalletSession(
      name: 'shared-name',
      repository: _FakeRepository(XelisNetwork.mainnet),
    );

    expect(
      isSessionForWalletTarget(mainnet, XelisNetwork.testnet, 'shared-name'),
      isFalse,
    );
  });

  test('session identity includes network, name, and repository identity', () {
    final repository = _FakeRepository(XelisNetwork.mainnet);
    final captured = WalletSession(name: 'wallet', repository: repository);

    expect(
      isSameWalletSession(
        WalletSession(name: 'wallet', repository: repository),
        captured,
      ),
      isTrue,
    );
    expect(
      isSameWalletSession(
        WalletSession(
          name: 'wallet',
          repository: _FakeRepository(XelisNetwork.mainnet),
        ),
        captured,
      ),
      isFalse,
    );
  });
}

final class _FakeRepository implements NativeWalletRepository {
  _FakeRepository(this.walletNetwork);

  final XelisNetwork walletNetwork;

  @override
  String get address => 'wallet-address';

  @override
  XelisNetwork get network => walletNetwork;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
