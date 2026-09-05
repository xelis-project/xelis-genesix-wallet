import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/router/extra_codec.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:genesix/features/router/xswd_session_reference_adapter.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  const codec = ExtraCodec(adapters: [XswdSessionReferenceAdapter()]);

  test('serializes no XSWD authority or application metadata', () {
    final reference = XelisXswdSessionReference.detached();

    final encoded = codec.encode(reference);

    expect(encoded, ['xswd_session_reference', 'non_restorable']);
    expect(encoded.toString(), isNot(contains(reference.toString())));
  });

  test('restoration creates a detached non-matching reference', () {
    final original = XelisXswdSessionReference.detached();
    final encoded = codec.encode(original);

    final restored = codec.decode(encoded);

    expect(restored, isA<XelisXswdSessionReference>());
    expect(restored, isNot(original));
  });

  test('ordinary typed route retains the original in-memory reference', () {
    final reference = XelisXswdSessionReference.detached();

    final route = XswdAppDetailRoute($extra: reference);

    expect(identical(route.$extra, reference), isTrue);
  });

  test('rejects an unexpected restoration payload', () {
    const adapter = XswdSessionReferenceAdapter();

    expect(() => adapter.decode('unexpected'), throwsFormatException);
  });
}
