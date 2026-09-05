import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_app_detail.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  for (final method in ['get_balance', 'network_info', 'store', 'sign_data']) {
    for (final width in [320.0, 800.0]) {
      testWidgets('$method permission consent at ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final loc = AppLocalizationsEn();
        final application = XelisXswdApplication(
          id: 'test-application',
          name: 'Test application',
          description: '',
          url: null,
          permissions: {method: XelisXswdPermissionPolicy.ask},
          isRelayer: false,
        );
        final sameIdDecoy = XelisXswdApplication(
          id: application.id,
          name: 'Same-ID decoy',
          description: '',
          url: null,
          permissions: const {
            'decoy_permission': XelisXswdPermissionPolicy.ask,
          },
          isRelayer: true,
        );
        final container = ProviderContainer(
          overrides: [
            appLocalizationsProvider.overrideWithValue(loc),
            settingsProvider.overrideWithValue(
              const SettingsState(locale: Locale('en')),
            ),
            xswdApplicationsProvider.overrideWith(
              (ref) async => [sameIdDecoy, application],
            ),
          ],
        );
        addTearDown(container.dispose);
        final theme = greenDark(touch: width < 600);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme.toApproximateMaterialTheme(),
              home: FTheme(
                data: theme,
                child: XswdAppDetail(
                  sessionReference: application.sessionReference,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(method), findsOneWidget);
        expect(find.text('Same-ID decoy'), findsNothing);
        if (method == 'sign_data') {
          expect(
            find.text(loc.xswd_permission_unsupported_impact),
            findsOneWidget,
          );
          expect(find.text(loc.allow), findsNothing);
          expect(
            find.textContaining(loc.xswd_permission_persistent_impact),
            findsNothing,
          );
        } else {
          final impact = method == 'store'
              ? loc.xswd_permission_app_storage_impact
              : loc.xswd_permission_wallet_data_impact;
          expect(find.text(impact), findsOneWidget);
          expect(
            find.text('${loc.allow}: ${loc.xswd_permission_persistent_impact}'),
            findsOneWidget,
          );
          expect(find.text(loc.allow), findsOneWidget);
          expect(
            tester.getTopLeft(find.text(impact)).dy,
            lessThan(tester.getTopLeft(find.text(loc.allow)).dy),
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
