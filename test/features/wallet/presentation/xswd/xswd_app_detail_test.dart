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
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
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
        if (method == 'get_balance' && width == 800) {
          await tester.tap(
            find.widgetWithText(FRadio, loc.xswd_permission_status_blocked),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text(loc.save));
          await tester.pump(const Duration(milliseconds: 150));
          expect(
            find.text(loc.xswd_permission_edit_not_confirmed),
            findsOneWidget,
          );
          expect(
            find.text(loc.xswd_edit_permission_title(copy.title)),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('shows recent choices only for the exact connection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loc = AppLocalizationsEn();
    final application = XelisXswdApplication(
      id: 'shared-id',
      name: 'Fictional vault',
      description: '',
      url: null,
      permissions: const {'get_balance': XelisXswdPermissionPolicy.ask},
      isRelayer: false,
    );
    final other = XelisXswdApplication(
      id: application.id,
      name: 'Other session',
      description: '',
      url: null,
      permissions: const {},
      isRelayer: true,
    );
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(loc),
        settingsProvider.overrideWithValue(
          const SettingsState(locale: Locale('en')),
        ),
        xswdApplicationsProvider.overrideWith((ref) async => [application]),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(xswdRecentChoicesProvider.notifier)
        .record(
          XswdRecentChoice(
            sessionReference: application.sessionReference,
            kind: XswdNoticeKind.prefetch,
            outcome: XswdChoiceOutcome.allowed,
            scope: XswdChoiceScope.connection,
            methods: const ['get_balance', 'subscribe'],
            grantedMethods: const ['get_balance'],
          ),
        );
    container
        .read(xswdApplicationObservationsProvider.notifier)
        .record(XelisXswdApplicationStateObserved(application, 1));
    container
        .read(xswdRecentChoicesProvider.notifier)
        .record(
          XswdRecentChoice(
            sessionReference: other.sessionReference,
            kind: XswdNoticeKind.permission,
            outcome: XswdChoiceOutcome.refused,
            scope: XswdChoiceScope.request,
            methods: const ['network_info'],
          ),
        );
    final theme = greenDark(touch: false);
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
    expect(find.text(loc.xswd_observation_confirmed), findsOneWidget);
    await tester.tap(find.text(loc.xswd_recent_choices_title));
    await tester.pumpAndSettle();

    expect(find.text(loc.prefetch_permissions_request), findsOneWidget);
    final granted = find.byKey(const ValueKey('xswd-choice-granted-methods'));
    final unchanged = find.byKey(
      const ValueKey('xswd-choice-unchanged-methods'),
    );
    final balanceTitle = xswdPermissionCopy(
      'get_balance',
      tryXswdMethodPolicyForKey('get_balance'),
      loc,
    ).title;
    final subscriptionTitle = xswdPermissionCopy(
      'subscribe',
      tryXswdMethodPolicyForKey('subscribe'),
      loc,
    ).title;
    expect(
      find.descendant(of: granted, matching: find.text(balanceTitle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: granted, matching: find.text(subscriptionTitle)),
      findsNothing,
    );
    expect(
      find.descendant(of: unchanged, matching: find.text(subscriptionTitle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: unchanged, matching: find.text(balanceTitle)),
      findsNothing,
    );
    expect(find.text(loc.xswd_permission_status_allowed), findsNothing);
    expect(find.textContaining('Network information'), findsNothing);
    expect(find.text(loc.xswd_recent_choices_disclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
