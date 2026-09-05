import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_value_presentation.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart' as wallet;

void main() {
  final loc = AppLocalizationsEn();

  test('RPC preview stays bounded while explicit formats stay exact', () {
    final longValue = '${List.filled(200000, 'a').join()}exact-tail';
    RpcValueCell cell = RpcValueCell.primitive(RpcPrimitive.string(longValue));
    for (var depth = 0; depth < 32; depth++) {
      cell = RpcValueCell.object([cell]);
    }

    final preview = xswdRpcValuePreview(loc, cell);

    expect(preview.text.length, lessThanOrEqualTo(96));
    expect(preview.isTruncated, isTrue);
    expect(preview.text, isNot(contains('exact-tail')));
    expect(xswdFormatRpcValue(cell), contains('exact-tail'));
    expect(xswdSerializeRpcValue(cell), contains('exact-tail'));
  });

  test('attached-data preview does not walk a large nested value', () {
    final wide = (BigInt.one << 255) + BigInt.from(123);
    final longValue = '${List.filled(200000, 'b').join()}exact-tail';
    DataElement element = DataElement.fields({
      'wide': DataElement.value(RpcJsonValue.integer(wide)),
      'payload': DataElement.value(RpcJsonValue.string(longValue)),
    });
    for (var depth = 0; depth < 32; depth++) {
      element = DataElement.array([element]);
    }

    final preview = xswdDataElementPreview(loc, element);
    final full = xswdFormatDataElement(element);

    expect(preview, '[1 items]');
    expect(preview, isNot(contains('exact-tail')));
    expect(full, contains(wide.toString()));
    expect(full, contains('exact-tail'));
  });

  test('unknown identifiers retain both ends and short values in full', () {
    expect(xswdAbbreviateIdentifier('asset-hash'), 'asset-hash');
    expect(
      xswdAbbreviateIdentifier('0123456789abcdef0123456789abcdef'),
      '01234567…89abcdef',
    );
  });

  test('integrated-data preview hides values and explicit format is exact', () {
    final wide = BigInt.parse('340282366920938463463374607431768211455');
    final data = wallet.XelisDataElement.fields([
      wallet.XelisDataField(
        key: const wallet.XelisDataValue.string('wide'),
        value: wallet.XelisDataElement.value(
          wallet.XelisDataValue.unsigned(
            type: wallet.XelisUnsignedIntegerType.u128,
            value: wide,
          ),
        ),
      ),
      const wallet.XelisDataField(
        key: wallet.XelisDataValue.string('text'),
        value: wallet.XelisDataElement.value(
          wallet.XelisDataValue.string('integrated-exact-tail'),
        ),
      ),
    ]);

    final preview = xswdIntegratedDataPreview(loc, data);
    final full = xswdFormatIntegratedData(data);

    expect(preview.type, 'fields');
    expect(preview.text, contains('Included'));
    expect(preview.text, isNot(contains(wide.toString())));
    expect(preview.text, isNot(contains('integrated-exact-tail')));
    expect(full, contains('u128(${wide.toString()})'));
    expect(full, contains('string("integrated-exact-tail")'));
  });
}
