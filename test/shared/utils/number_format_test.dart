import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:intl/intl.dart' show Intl;

void main() {
  group('formatBigInt', () {
    test('groups values accepted safely by NumberFormat', () {
      expect(formatBigInt(BigInt.from(1234567), locale: 'en_US'), '1,234,567');
    });

    test('preserves integers beyond JavaScript safe precision', () {
      expect(
        formatBigInt(BigInt.parse('900719925474099312345'), locale: 'en_US'),
        '900,719,925,474,099,312,345',
      );
    });

    test('preserves the localized sign for large negative integers', () {
      expect(
        formatBigInt(BigInt.parse('-900719925474099312345'), locale: 'en_US'),
        '-900,719,925,474,099,312,345',
      );
    });
  });

  group('formatAtomicAmount', () {
    test('preserves values beyond JavaScript safe precision with decimals', () {
      final amount = BigInt.parse('900719925474099312345');

      expect(formatAtomicAmount(amount, 8), '9007199254740.99312345');
      Intl.withLocale('en_US', () {
        expect(formatCoin(amount, 8, 'TST'), '9,007,199,254,740.99312345 TST');
      });
    });

    test('pads the fractional part exactly', () {
      expect(formatAtomicAmount(BigInt.from(42), 8), '0.00000042');
    });

    test('preserves negative values', () {
      expect(formatAtomicAmount(BigInt.from(-1234), 2), '-12.34');
    });
  });
}
