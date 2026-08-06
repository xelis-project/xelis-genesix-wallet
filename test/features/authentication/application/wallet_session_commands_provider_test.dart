import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_commands_provider.dart';

void main() {
  test('accepts zero or one recovery source and rejects two', () {
    expect(
      hasAmbiguousWalletRecoverySources(seed: null, privateKey: null),
      isFalse,
    );
    expect(
      hasAmbiguousWalletRecoverySources(seed: 'seed', privateKey: null),
      isFalse,
    );
    expect(
      hasAmbiguousWalletRecoverySources(seed: null, privateKey: 'key'),
      isFalse,
    );
    expect(
      hasAmbiguousWalletRecoverySources(seed: 'seed', privateKey: 'key'),
      isTrue,
    );
  });
}
