import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';

void main() {
  test('chunk bounds reconstruct large UTF-16 content without loss', () {
    final value =
        '${List.filled(2047, 'a').join()}😀'
        '${List.filled(2500, 'b').join()}\n'
        '${List.filled(2 * 1024 * 1024, 'c').join()}exact-tail';

    final bounds = xswdChunkBounds(value);
    final reconstructed = StringBuffer();
    var expectedStart = 0;
    for (final chunk in bounds) {
      expect(chunk.start, expectedStart);
      expect(chunk.end, greaterThan(chunk.start));
      expect(chunk.end - chunk.start, lessThanOrEqualTo(2048));
      if (chunk.start > 0) {
        expect(_isLowSurrogate(value.codeUnitAt(chunk.start)), isFalse);
      }
      if (chunk.end < value.length) {
        expect(_isHighSurrogate(value.codeUnitAt(chunk.end - 1)), isFalse);
      }
      reconstructed.write(value.substring(chunk.start, chunk.end));
      expectedStart = chunk.end;
    }

    expect(expectedStart, value.length);
    expect(reconstructed.toString(), value);
    expect(reconstructed.toString(), endsWith('exact-tail'));
  });
}

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xd800 && codeUnit <= 0xdbff;

bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xdc00 && codeUnit <= 0xdfff;
