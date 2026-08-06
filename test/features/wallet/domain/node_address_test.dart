import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';

void main() {
  test('daemon origin validation mirrors the stable package contract', () {
    for (final value in [
      'https://node.xelis.io/',
      'http://127.0.0.1:8080',
      'ws://localhost:8080',
      'wss://node.xelis.io',
      'node.xelis.io',
      '127.0.0.1:8080',
    ]) {
      expect(isValidDaemonOrigin(value), isTrue, reason: value);
    }

    for (final value in [
      '',
      'not a valid origin',
      'ftp://node.xelis.io',
      'https://user:secret@node.xelis.io',
      'https://node.xelis.io/custom',
      'https://node.xelis.io/?token=secret',
      'https://node.xelis.io/#fragment',
    ]) {
      expect(isValidDaemonOrigin(value), isFalse, reason: value);
    }
  });
}
