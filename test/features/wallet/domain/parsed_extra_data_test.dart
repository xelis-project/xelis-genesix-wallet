import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  final localizations = AppLocalizationsEn();

  test('formats one typed element without inventing a history flag', () {
    const data = XelisDataElement.value(
      XelisDataValue.string('integrated-payment-reference'),
    );

    final parsed = ParsedXelisDataElement.parse(localizations, data);

    expect(parsed.pretty, 'integrated-payment-reference');
    expect(parsed.copyText, 'integrated-payment-reference');
    expect(parsed.label, localizations.text);
    expect(parsed.suggestedExt, '.txt');
    expect(parsed.bytesLength, utf8.encode(parsed.pretty).length);
  });

  test('displays and copies a typed string payload without JSON quotes', () {
    const extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.proprietary,
      hasPayload: true,
      payload: XelisDataElement.value(XelisDataValue.string('hello\nworld')),
    );

    final parsed = ParsedExtraData.parse(localizations, extraData);

    expect(parsed.extra, same(extraData));
    expect(parsed.pretty, 'hello\nworld');
    expect(parsed.copyText, 'hello\nworld');
    expect(parsed.label, localizations.text);
    expect(parsed.suggestedExt, '.txt');
    expect(parsed.bytesLength, utf8.encode('hello\nworld').length);
  });

  test('renders typed structures with explicit lossless value tags', () {
    final extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.public,
      hasPayload: true,
      payload: XelisDataElement.fields([
        XelisDataField(
          key: XelisDataValue.unsigned(
            type: XelisUnsignedIntegerType.u8,
            value: BigInt.from(7),
          ),
          value: XelisDataElement.value(
            XelisDataValue.unsigned(
              type: XelisUnsignedIntegerType.u128,
              value: BigInt.parse('340282366920938463463374607431768211455'),
            ),
          ),
        ),
      ]),
    );

    final parsed = ParsedExtraData.parse(localizations, extraData);

    expect(parsed.pretty, contains('"fields"'));
    expect(parsed.pretty, contains('"u8": "7"'));
    expect(
      parsed.pretty,
      contains('"u128": "340282366920938463463374607431768211455"'),
    );
    expect(parsed.copyText, parsed.pretty);
    expect(parsed.label, 'JSON');
    expect(parsed.suggestedExt, '.json');
    expect(parsed.bytesLength, utf8.encode(parsed.pretty).length);
  });

  test('preserves a typed top-level u128 without converting it to num', () {
    final value = BigInt.parse('340282366920938463463374607431768211455');
    final extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.public,
      hasPayload: true,
      payload: XelisDataElement.value(
        XelisDataValue.unsigned(
          type: XelisUnsignedIntegerType.u128,
          value: value,
        ),
      ),
    );

    final parsed = ParsedExtraData.parse(localizations, extraData);

    expect(parsed.pretty, value.toString());
    expect(parsed.copyText, value.toString());
    expect(parsed.label, 'U128');
    expect(parsed.bytesLength, 16);
  });

  test('renders a typed textual blob as UTF-8', () {
    final extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.public,
      hasPayload: true,
      payload: XelisDataElement.value(XelisDataValue.blob([72, 105])),
    );

    final parsed = ParsedExtraData.parse(localizations, extraData);

    expect(parsed.pretty, 'Hi');
    expect(parsed.copyText, 'Hi');
    expect(parsed.label, 'UTF-8');
    expect(parsed.bytesLength, 2);
    expect(parsed.suggestedExt, '.txt');
  });

  test('renders a typed binary blob as hexadecimal bytes', () {
    final extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.private,
      hasPayload: true,
      payload: XelisDataElement.value(XelisDataValue.blob([0, 255, 1])),
    );

    final parsed = ParsedExtraData.parse(localizations, extraData);

    expect(parsed.pretty, contains('00ff01'));
    expect(parsed.copyText, '00ff01');
    expect(parsed.label, localizations.bytes);
    expect(parsed.bytesLength, 3);
    expect(parsed.suggestedExt, '.bin');
  });

  test('does not invent a zero-byte payload when details are redacted', () {
    const extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.private,
      hasPayload: true,
    );

    final parsed = ParsedExtraData.parse(localizations, extraData);

    expect(parsed.label, localizations.not_available);
    expect(parsed.pretty, localizations.not_available);
    expect(parsed.copyText, isEmpty);
    expect(parsed.bytesLength, isNull);
    expect(parsed.fmtSize, isNull);
  });
}
