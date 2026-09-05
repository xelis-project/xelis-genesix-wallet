/// Pre-deserialization limits for the SDK's untrusted XSWD scalar codecs.
///
/// This bounds scalar storage, not the complete protocol serialization size.
/// The native wallet remains responsible for final transaction validation.
const maxXswdRpcScalarBytes = 256 * 1024;
const _maxCells = 4096;
const _maxDepth = 64;

BigInt parseXswdUnsignedInteger(Object? value, {int bits = 64}) {
  final maxDigits = switch (bits) {
    8 => 3,
    16 => 5,
    32 => 10,
    64 => 20,
    128 => 39,
    256 => 78,
    _ => throw ArgumentError('Unsupported XSWD unsigned width.'),
  };
  if (value is String) {
    // Check length before scanning or allocating a BigInt. Only canonical
    // decimal strings are reviewable; no signs, radix prefixes or padding.
    if (value.isEmpty ||
        value.length > maxDigits ||
        (value.length > 1 && value.codeUnitAt(0) == 0x30)) {
      throw const FormatException('Invalid XSWD unsigned integer.');
    }
    for (var index = 0; index < value.length; index++) {
      final unit = value.codeUnitAt(index);
      if (unit < 0x30 || unit > 0x39) {
        throw const FormatException('Invalid XSWD unsigned integer.');
      }
    }
  }
  final integer = switch (value) {
    BigInt integer => integer,
    int integer => BigInt.from(integer),
    String decimal => BigInt.parse(decimal, radix: 10),
    _ => null,
  };
  if (integer == null || integer.isNegative || integer.bitLength > bits) {
    throw const FormatException('Invalid XSWD unsigned integer.');
  }
  return integer;
}

/// Walks raw SDK ValueCells before they can allocate decoded hex or BigInts.
void validateXswdRpcParameterBudget(List<dynamic> parameters) {
  final budget = _RpcScalarBudget();
  for (final value in parameters) {
    budget.cell(value, 0);
  }
}

final class _RpcScalarBudget {
  int _cells = 0;
  int _bytes = 0;

  void cell(Object? raw, int depth) {
    if (++_cells > _maxCells) _reject();
    final map = _object(raw, depth);
    final value = map['value'];
    switch (map['type']) {
      case 'primitive':
        primitive(value, depth + 1);
      case 'bytes':
        if (value is! String || value.length.isOdd) _reject();
        addBytes(value.length ~/ 2);
      // The SDK validates hex syntax after this allocation budget check.
      case 'object':
        if (value is! List) _reject();
        for (final child in value) {
          cell(child, depth + 1);
        }
      case 'map':
        if (value is! List) _reject();
        for (final pair in value) {
          if (pair is! List || pair.length != 2) _reject();
          cell(pair[0], depth + 1);
          cell(pair[1], depth + 1);
        }
      default:
        _reject();
    }
  }

  void primitive(Object? raw, int depth) {
    final map = _object(raw, depth);
    final value = map['value'];
    final bits = switch (map['type']) {
      'u8' => 8,
      'u16' => 16,
      'u32' => 32,
      'u64' => 64,
      'u128' => 128,
      'u256' => 256,
      _ => null,
    };
    if (bits != null) {
      parseXswdUnsignedInteger(value, bits: bits);
      addBytes(bits ~/ 8);
      return;
    }
    switch (map['type']) {
      case 'null':
        break;
      case 'boolean':
        if (value is! bool) _reject();
        addBytes(1);
      case 'string':
        if (value is! String) _reject();
        addText(value);
      case 'range':
        if (value is! List || value.length != 2) _reject();
        primitive(value[0], depth + 1);
        primitive(value[1], depth + 1);
      case 'opaque':
        final opaque = _object(value, depth + 1);
        final text = opaque['value'];
        if (text is! String) _reject();
        addText(text);
      default:
        _reject();
    }
  }

  void addBytes(int count) {
    _bytes += count;
    if (_bytes > maxXswdRpcScalarBytes) _reject();
  }

  void addText(String value) {
    // Count UTF-8 without creating an encoded copy. Valid surrogate pairs use
    // four bytes; unpaired units have the replacement character's three bytes.
    for (var index = 0; index < value.length; index++) {
      final unit = value.codeUnitAt(index);
      if (unit < 0x80) {
        addBytes(1);
      } else if (unit < 0x800) {
        addBytes(2);
      } else if (unit >= 0xd800 &&
          unit <= 0xdbff &&
          index + 1 < value.length &&
          value.codeUnitAt(index + 1) >= 0xdc00 &&
          value.codeUnitAt(index + 1) <= 0xdfff) {
        addBytes(4);
        index++;
      } else {
        addBytes(3);
      }
    }
  }
}

Map<String, dynamic> _object(Object? value, int depth) {
  if (depth > _maxDepth || value is! Map<String, dynamic>) _reject();
  return value;
}

Never _reject() =>
    throw const FormatException('XSWD RPC scalar budget exceeded.');
