import 'package:genesix/shared/utils/atomic_amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAtomicAmount', () {
    test('normalizes equivalent canonical decimal representations', () {
      expect(parseAtomicAmount('1', 8), BigInt.from(100000000));
      expect(parseAtomicAmount('1.0', 8), BigInt.from(100000000));
      expect(parseAtomicAmount('1.00000000', 8), BigInt.from(100000000));
      expect(parseAtomicAmount('0001.2300', 4), BigInt.from(12300));
      expect(parseAtomicAmount('0.00000001', 8), BigInt.one);
    });

    test('preserves values beyond JavaScript safe integer precision', () {
      expect(
        parseAtomicAmount('90071992.54740993', 8),
        BigInt.parse('9007199254740993'),
      );
    });

    test('accepts the unsigned 64-bit maximum exactly', () {
      expect(
        parseAtomicAmount('18446744073709551615', 0),
        BigInt.parse('18446744073709551615'),
      );
      expect(
        parseAtomicAmount('184467440737.09551615', 8),
        BigInt.parse('18446744073709551615'),
      );
    });

    test('rejects values above the unsigned 64-bit maximum', () {
      expect(
        () => parseAtomicAmount('18446744073709551616', 0),
        throwsFormatException,
      );
      expect(
        () => parseAtomicAmount('184467440737.09551616', 8),
        throwsFormatException,
      );
    });

    test('rejects a very long numeric input before integer conversion', () {
      final value = List.filled(10000, '9').join();

      expect(() => parseAtomicAmount(value, 8), throwsFormatException);
    });

    test('normalizes arbitrarily many leading zeros before range checks', () {
      final value = '${List.filled(10000, '0').join()}18446744073709551615';

      expect(parseAtomicAmount(value, 0), BigInt.parse('18446744073709551615'));
    });

    test('rejects non-canonical and signed input', () {
      for (final value in <String>[
        '',
        ' ',
        ' 1',
        '1 ',
        '+1',
        '-1',
        '.1',
        '1.',
        '1e3',
        'NaN',
        'Infinity',
        '1,0',
        '1_0',
        'amount',
      ]) {
        expect(
          () => parseAtomicAmount(value, 8),
          throwsFormatException,
          reason: value,
        );
      }
    });

    test('rejects fractional precision beyond the asset contract', () {
      expect(() => parseAtomicAmount('1.001', 2), throwsFormatException);
      expect(() => parseAtomicAmount('1.0', 0), throwsFormatException);
    });

    test('requires a positive amount unless zero is explicitly allowed', () {
      expect(() => parseAtomicAmount('0', 8), throwsFormatException);
      expect(() => parseAtomicAmount('0.00000000', 8), throwsFormatException);
      expect(
        parseAtomicAmount('0.00000000', 8, requirePositive: false),
        BigInt.zero,
      );
    });

    test('rejects a negative decimal precision as a programmer error', () {
      expect(() => parseAtomicAmount('1', -1), throwsArgumentError);
    });

    test('rejects decimal precision outside the native u8 contract', () {
      expect(() => parseAtomicAmount('1', 256), throwsArgumentError);
    });
  });
}
