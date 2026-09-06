import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('marks transfer summaries that contain attached data', () {
    final info = parseTxInfo(
      AppLocalizationsEn(),
      XelisNetwork.mainnet,
      XelisWalletOutgoingEntry(
        transfers: [
          XelisWalletTransferOut(
            destination: 'xel:destination',
            asset: _asset,
            amount: BigInt.one,
            extraData: _extraData,
          ),
        ],
        fee: BigInt.one,
        nonce: BigInt.one,
      ),
      LinkedHashMap(),
      const {},
    );

    expect(info.hasAttachedData, isTrue);
    expect(info.attachedDataBadgeLabel, 'Data');
    expect(info.attachedDataSemanticLabel, 'Attached data');
  });

  test('does not mark transfer summaries without attached data', () {
    final info = parseTxInfo(
      AppLocalizationsEn(),
      XelisNetwork.mainnet,
      XelisWalletIncomingEntry(
        from: 'xel:source',
        transfers: [XelisWalletTransferIn(asset: _asset, amount: BigInt.one)],
      ),
      LinkedHashMap(),
      const {},
    );

    expect(info.hasAttachedData, isFalse);
  });

  test('uses only an exact destination match in outgoing detail summary', () {
    final entry = XelisWalletOutgoingEntry(
      transfers: [
        XelisWalletTransferOut(
          destination: 'xel:shared-base',
          asset: _asset,
          amount: BigInt.one,
          extraData: _extraData,
        ),
      ],
      fee: BigInt.one,
      nonce: BigInt.one,
    );
    final addressBook = {
      'xel:shared-base': const XelisAddressBookEntry(
        id: 'base-entry',
        displayName: 'Wrong base-only contact',
        destination: XelisSavedDestination(
          address: 'xel:shared-base',
          baseAddress: 'xel:shared-base',
          kind: XelisSavedDestinationKind.standard,
          integratedDataKind: null,
        ),
      ),
    };
    final exactInfo = parseTxInfo(
      AppLocalizationsEn(),
      XelisNetwork.mainnet,
      entry,
      LinkedHashMap(),
      addressBook,
      exactDestinations: [
        const XelisAddressBookEntry(
          id: 'exact-entry',
          displayName: 'Exact integrated contact',
          destination: XelisSavedDestination(
            address: 'xel:full-integrated',
            baseAddress: 'xel:shared-base',
            kind: XelisSavedDestinationKind.integrated,
            integratedDataKind: XelisIntegratedDataKind.string,
          ),
        ),
      ],
    );
    final unmatchedInfo = parseTxInfo(
      AppLocalizationsEn(),
      XelisNetwork.mainnet,
      entry,
      LinkedHashMap(),
      addressBook,
    );

    expect(exactInfo.subtitle, contains('Exact integrated contact'));
    expect(exactInfo.subtitle, isNot(contains('shared-base')));
    expect(unmatchedInfo.subtitle, isNot(contains('Wrong base-only contact')));
  });

  testWidgets('renders compact attached-data metadata in transaction suffix', (
    tester,
  ) async {
    final theme = greenDark(touch: false);
    final info = TransactionDisplayInfo(
      icon: Icons.arrow_upward,
      color: Colors.red,
      label: 'Transfer',
      attachedDataBadgeLabel: 'Data',
      attachedDataSemanticLabel: 'Attached data',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme.toApproximateMaterialTheme(),
        home: GenesixTheme(
          data: theme,
          child: Scaffold(body: TransactionInfoSuffix(info: info)),
        ),
      ),
    );

    expect(find.text('Data'), findsOneWidget);
  });
}

const _asset =
    '0000000000000000000000000000000000000000000000000000000000000000';
const _extraData = XelisWalletExtraData(
  flag: XelisWalletExtraDataFlag.private,
  hasPayload: true,
);
