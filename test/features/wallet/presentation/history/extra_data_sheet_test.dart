import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_sheet.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets(
    'reveals typed integrated data without inventing a history flag',
    (tester) async {
      final localizations = AppLocalizationsEn();
      final theme = greenDark(touch: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalizationsProvider.overrideWithValue(localizations),
          ],
          child: MaterialApp(
            theme: theme.toApproximateMaterialTheme(),
            home: FTheme(
              data: theme,
              child: Scaffold(
                body: ExtraDataSheet.typed(
                  data: XelisDataElement.value(
                    XelisDataValue.string('typed memo'),
                  ),
                  visibleInAddress: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('typed memo'), findsOneWidget);
      expect(
        find.text(localizations.receive_integrated_address_data_visible),
        findsOneWidget,
      );
      expect(
        find.text(
          localizations.receive_integrated_address_data_visible_description,
        ),
        findsOneWidget,
      );
      for (final flag in XelisWalletExtraDataFlag.values) {
        expect(find.text(flag.name), findsNothing);
      }
    },
  );
}
