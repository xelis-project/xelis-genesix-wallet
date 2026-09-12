import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_app_detail.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_permission_copy.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  for (final method in [
    'get_balance',
    'network_info',
    'store',
    'subscribe',
    'unsubscribe',
    'build_transaction',
    'sign_data',
  ]) {
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
              home: GenesixTheme(
                data: theme,
                child: XswdAppDetail(
                  sessionReference: application.sessionReference,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final policy = tryXswdMethodPolicyForKey(method);
        final copy = xswdPermissionCopy(method, policy, loc);
        expect(find.text(method), findsOneWidget);
        expect(find.text(copy.title), findsOneWidget);
        expect(find.text(copy.description), findsOneWidget);
        expect(find.text('Same-ID decoy'), findsNothing);
        if (method == 'sign_data') {
          expect(
            find.text(loc.xswd_permission_status_unsupported),
            findsOneWidget,
          );
        } else {
          expect(find.text(loc.xswd_permission_status_ask), findsOneWidget);
        }

        final permissionTile = find.ancestor(
          of: find.text(method),
          matching: find.byType(FTile),
        );
        await tester.ensureVisible(permissionTile);
        await tester.tap(permissionTile);
        await tester.pump(const Duration(milliseconds: 150));

        expect(
          find.text(loc.xswd_edit_permission_title(copy.title)),
          findsOneWidget,
        );
        expect(find.text(loc.xswd_permission_status_blocked), findsOneWidget);
        if (method == 'sign_data') {
          expect(
            find.text(loc.xswd_permission_status_unsupported),
            findsWidgets,
          );
          expect(find.text(loc.xswd_permission_status_allowed), findsNothing);
        } else {
          expect(find.text(loc.xswd_permission_status_ask), findsWidgets);
          expect(
            find.text(loc.xswd_permission_status_allowed),
            method == 'build_transaction' ? findsNothing : findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
