import 'dart:collection';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/history/blob_entry_content.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets(
    'keeps incoming blob destinations raw without an exact typed match',
    (tester) async {
      final localizations = AppLocalizationsEn();
      final theme = greenDark(touch: false);
      const destination = 'xel:shared-base';
      const standardContact = XelisAddressBookEntry(
        id: 'standard',
        displayName: 'Wrong standard contact',
        destination: XelisSavedDestination(
          address: destination,
          baseAddress: destination,
          kind: XelisSavedDestinationKind.standard,
          integratedDataKind: null,
        ),
      );
      final entry = XelisWalletIncomingBlobEntry(
        from: 'xel:sender',
        destinations: const [destination],
        data: const XelisWalletExtraData(
          flag: XelisWalletExtraDataFlag.public,
          hasPayload: true,
          payload: XelisDataElement.value(
            XelisDataValue.string('typed blob data'),
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
            settingsProvider.overrideWithValue(
              const SettingsState(locale: Locale('en')),
            ),
            walletRuntimeProvider.overrideWithValue(
              WalletRuntimeState(
                topoheight: BigInt.zero,
                xelisBalance: BigInt.zero,
                trackedBalances: LinkedHashMap(),
                knownAssets: LinkedHashMap(),
              ),
            ),
            addressBookByAddressProvider.overrideWithValue(
              const AsyncData({destination: standardContact}),
            ),
          ],
          child: MaterialApp(
            theme: theme.toApproximateMaterialTheme(),
            home: GenesixTheme(
              data: theme,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BlobEntryContent.incoming(entry),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(destination), findsOneWidget);
      expect(find.text('Wrong standard contact'), findsNothing);
      expect(find.byType(AddressWidget), findsOneWidget);
    },
  );
}
