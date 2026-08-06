/// Parses a canonical, non-localized decimal amount into atomic units.
///
/// The accepted syntax contains decimal digits and, when [decimals] is
/// positive, an optional `.` followed by at least one decimal digit. Signs,
/// exponents, localized separators, whitespace, and non-finite values are
/// rejected. The conversion never passes through `double`, so every value up
/// to the native wallet's unsigned 64-bit limit remains exact.
///
/// By default the resulting amount must be strictly positive. Set
/// [requirePositive] to `false` for callers whose contract explicitly permits
/// zero.
BigInt parseAtomicAmount(
  String value,
  int decimals, {
  bool requirePositive = true,
}) {
  if (decimals < 0) {
    throw ArgumentError.value(decimals, 'decimals', 'Must be >= 0');
  }
  if (decimals > 255) {
    throw ArgumentError.value(decimals, 'decimals', 'Must be <= 255');
  }

  final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(value);
  if (match == null) {
    throw const FormatException('Amount must be a canonical decimal value.');
  }

  final fractionalDigits = match.group(2) ?? '';
  if (fractionalDigits.length > decimals) {
    throw FormatException(
      'Amount has more than $decimals decimal places.',
      value,
    );
  }

  final wholeDigits = _withoutLeadingZeros(match.group(1)!);
  if (wholeDigits.isNotEmpty && wholeDigits.length + decimals > 20) {
    throw const FormatException(
      'Amount exceeds the native unsigned 64-bit limit.',
    );
  }

  final atomicDigits =
      '$wholeDigits${fractionalDigits.padRight(decimals, '0')}';
  final significantDigits = _withoutLeadingZeros(atomicDigits);
  if (significantDigits.isEmpty) {
    if (!requirePositive) return BigInt.zero;
    throw const FormatException('Amount must be strictly positive.');
  }
  if (significantDigits.length > 20 ||
      significantDigits.length == 20 &&
          significantDigits.compareTo(_maxUnsigned64Digits) > 0) {
    throw const FormatException(
      'Amount exceeds the native unsigned 64-bit limit.',
    );
  }

  return BigInt.parse(significantDigits);
}

String _withoutLeadingZeros(String digits) {
  var firstSignificantDigit = 0;
  while (firstSignificantDigit < digits.length &&
      digits.codeUnitAt(firstSignificantDigit) == _zeroCodeUnit) {
    firstSignificantDigit++;
  }
  return firstSignificantDigit == digits.length
      ? ''
      : digits.substring(firstSignificantDigit);
}

const _maxUnsigned64Digits = '18446744073709551615';
const _zeroCodeUnit = 0x30;
