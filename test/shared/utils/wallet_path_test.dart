import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/utils/wallet_path.dart';
import 'package:path/path.dart' as p;

void main() {
  group('isValidWalletName', () {
    test('accepts portable leaf names', () {
      for (final name in ['alice', 'My Wallet', '.hidden', 'Épargne']) {
        expect(isValidWalletName(name), isTrue, reason: name);
      }
    });

    test('rejects empty, relative, absolute, and nested paths', () {
      for (final name in [
        '',
        '   ',
        '.',
        '..',
        '../escape',
        r'..\escape',
        'folder/child',
        r'folder\child',
        '/absolute',
        r'C:\absolute',
        r'\\server\share',
        '//server/share',
      ]) {
        expect(isValidWalletName(name), isFalse, reason: name);
      }
    });

    test('rejects control and Windows-invalid characters', () {
      for (final name in [
        'nul\u0000byte',
        'new\nline',
        'delete\u007fcharacter',
        'less<than',
        'greater>than',
        'colon:name',
        'double"quote',
        'pipe|name',
        'question?mark',
        'asterisk*name',
        'trailing.',
        'trailing ',
      ]) {
        expect(isValidWalletName(name), isFalse, reason: name);
      }
    });

    test('rejects Windows device names case-insensitively', () {
      for (final name in [
        'CON',
        'con',
        'con.wallet',
        'PRN',
        'AUX',
        'NUL',
        'CLOCK\$',
        'CONIN\$',
        'CONOUT\$',
        'COM1',
        'com9.backup',
        'COM¹',
        'COM²',
        'COM³',
        'LPT1',
        'lpt9.backup',
        'LPT¹',
        'LPT²',
        'LPT³',
      ]) {
        expect(isValidWalletName(name), isFalse, reason: name);
      }

      expect(isValidWalletName('COM10'), isTrue);
      expect(isValidWalletName('LPT10'), isTrue);
    });
  });

  group('resolveWalletPath', () {
    test('normalizes a path strictly inside a Windows network directory', () {
      final context = p.Context(style: p.Style.windows);

      final result = resolveWalletPath(
        walletsDirectory: r'C:\wallets\.\store',
        networkName: 'mainnet',
        walletName: 'alice',
        pathContext: context,
      );

      expect(result, r'C:\wallets\store\mainnet\alice');
      expect(context.isWithin(r'C:\wallets\store\mainnet', result), isTrue);
    });

    test('normalizes a path strictly inside a POSIX network directory', () {
      final context = p.Context(style: p.Style.posix);

      final result = resolveWalletPath(
        walletsDirectory: '/wallets/./store',
        networkName: 'testnet',
        walletName: 'alice',
        pathContext: context,
      );

      expect(result, '/wallets/store/testnet/alice');
      expect(context.isWithin('/wallets/store/testnet', result), isTrue);
    });

    test('preserves a relative URL-style web storage path', () {
      final context = p.Context(style: p.Style.url);

      final result = resolveWalletPath(
        walletsDirectory: '___xelis_db___/wallets',
        networkName: 'devnet',
        walletName: 'alice',
        pathContext: context,
      );

      expect(result, '___xelis_db___/wallets/devnet/alice');
    });

    test('rejects traversal before resolving the candidate', () {
      final context = p.Context(style: p.Style.posix);

      expect(
        () => resolveWalletPath(
          walletsDirectory: '/wallets',
          networkName: 'mainnet',
          walletName: '../escape',
          pathContext: context,
        ),
        throwsA(isA<InvalidWalletNameException>()),
      );
    });

    test('does not expose the rejected name in exception text', () {
      const rejectedName = '../private-wallet';

      try {
        resolveWalletPath(
          walletsDirectory: '/wallets',
          networkName: 'mainnet',
          walletName: rejectedName,
          pathContext: p.Context(style: p.Style.posix),
        );
        fail('Expected InvalidWalletNameException');
      } on InvalidWalletNameException catch (error) {
        expect(error.toString(), isNot(contains(rejectedName)));
      }
    });
  });

  test('unsafe entity exception never retains a wallet path', () {
    const walletPath = r'C:\wallets\mainnet\sensitive-name';
    const error = UnsafeWalletPathException();

    expect(error.toString(), isNot(contains(walletPath)));
  });
}
