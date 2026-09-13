import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
import 'package:genesix/src/generated/l10n/app_localizations_fr.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' show WalletEvent;
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
        final actionLabel = xswdPermissionActionLabel(method, loc);
        expect(find.text(actionLabel), findsOneWidget);
        expect(find.text(copy.description), findsNothing);
        expect(find.text('Same-ID decoy'), findsNothing);
        if (method == 'sign_data') {
          expect(
            find.text('${loc.xswd_permission_group_unsupported} (1)'),
            findsOneWidget,
          );
        } else {
          expect(
            find.text('${loc.xswd_permission_group_ask} (1)'),
            findsOneWidget,
          );
        }

        final permissionTile = find.ancestor(
          of: find.text(actionLabel),
          matching: find.byType(FTile),
        );
        await tester.ensureVisible(permissionTile);
        await tester.tap(permissionTile);
        await tester.pump(const Duration(milliseconds: 150));

        expect(
          find.text(loc.xswd_edit_permission_title(copy.title)),
          findsOneWidget,
        );
        expect(find.text(copy.description), findsOneWidget);
        expect(find.text(method).hitTestable(), findsNothing);
        expect(find.text(loc.xswd_permission_status_blocked), findsOneWidget);
        if (method == 'sign_data') {
          expect(find.text(loc.xswd_permission_status_allowed), findsNothing);
        } else {
          expect(find.text(loc.xswd_permission_status_ask), findsWidgets);
          expect(
            find.text(loc.xswd_permission_status_allowed),
            method == 'build_transaction' ? findsNothing : findsOneWidget,
          );
        }
        await tester.tap(
          find.descendant(
            of: find.byKey(const ValueKey('xswd-permission-technical-details')),
            matching: find.text(loc.details),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(method), findsOneWidget);
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

  testWidgets('groups rules and keeps the app summary compact', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loc = AppLocalizationsFr();
    const longUrl =
        'https://example.invalid/a/very/long/declared/application/origin';
    final application = XelisXswdApplication(
      id: 'fictional-app',
      name: 'Coffre fictif avec un nom volontairement long',
      description: 'Une application fictive utilisée pour les tests.',
      url: longUrl,
      permissions: const {
        'get_address': XelisXswdPermissionPolicy.accept,
        'get_balance': XelisXswdPermissionPolicy.ask,
        'get_assets': XelisXswdPermissionPolicy.reject,
        'sign_data': XelisXswdPermissionPolicy.ask,
      },
      isRelayer: false,
    );
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(loc),
        settingsProvider.overrideWithValue(
          const SettingsState(locale: Locale('fr')),
        ),
        xswdApplicationsProvider.overrideWith((ref) async => [application]),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(xswdApplicationObservationsProvider.notifier)
        .record(XelisXswdApplicationStateObserved(application, 1));
    final theme = greenDark(touch: true);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
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

    expect(
      find.text('${loc.xswd_permission_group_allowed} (1)'),
      findsOneWidget,
    );
    expect(find.text('${loc.xswd_permission_group_ask} (1)'), findsOneWidget);
    expect(
      find.text('${loc.xswd_permission_group_blocked} (1)'),
      findsOneWidget,
    );
    expect(
      find.text('${loc.xswd_permission_group_unsupported} (1)'),
      findsOneWidget,
    );
    for (final groupKey in const [
      'xswd-permission-group-allowed',
      'xswd-permission-group-ask',
      'xswd-permission-group-blocked',
      'xswd-permission-group-unsupported',
    ]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey(groupKey)),
          matching: find.byType(FBadge),
        ),
        findsNothing,
      );
    }
    expect(tester.getTopLeft(find.text(application.name)).dy, lessThan(200));
    expect(
      tester.getSize(find.widgetWithText(FButton, loc.disconnect)).width,
      lessThan(240),
    );
    expect(
      find.byKey(const ValueKey('xswd-observation-warning')),
      findsNothing,
    );

    await tester.tap(find.text(loc.details));
    await tester.pumpAndSettle();
    final fullOrigin = find.byKey(const ValueKey('xswd-app-full-origin'));
    expect(fullOrigin, findsOneWidget);
    expect(tester.widget<SelectableText>(fullOrigin).data, longUrl);

    final actionLabel = xswdPermissionActionLabel('get_address', loc);
    final permissionTile = find.byKey(
      const ValueKey('xswd-permission-get_address'),
    );
    await tester.ensureVisible(permissionTile);
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(
      find.bySemanticsLabel(
        '$actionLabel, ${loc.xswd_permission_status_allowed}',
      ),
      findsOneWidget,
    );
    final permissionFocusNode = tester.widget<FTile>(permissionTile).focusNode!;
    permissionFocusNode.requestFocus();
    await tester.pump();
    expect(permissionFocusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.text(
        loc.xswd_edit_permission_title(
          xswdPermissionCopy(
            'get_address',
            tryXswdMethodPolicyForKey('get_address'),
            loc,
          ).title,
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FButton, loc.cancel_button));
    await tester.pumpAndSettle();
    expect(permissionFocusNode.hasFocus, isTrue);
    container
        .read(xswdApplicationObservationsProvider.notifier)
        .record(XelisXswdApplicationStateTimedOut(application, 2));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('xswd-observation-warning')),
      findsOneWidget,
    );
    container
        .read(xswdApplicationObservationsProvider.notifier)
        .record(
          XelisXswdApplicationStateFailed(
            application,
            3,
            const XelisWalletOperationException(
              source: XelisWalletErrorSource.xelisWallet,
              operation: XelisWalletOperation.walletXswdStateRead,
              code: XelisWalletErrorCode.internal,
              supportId: 'XWF-TEST-OBSERVATION',
              diagnosticMessage: 'sensitive-observation-sentinel',
            ),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text(loc.error_loading_applications), findsOneWidget);
    expect(find.textContaining('sensitive-observation-sentinel'), findsNothing);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows recent choices only for the exact connection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
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
        .read(xswdRecentChoicesProvider.notifier)
        .record(
          XswdRecentChoice(
            sessionReference: application.sessionReference,
            kind: XswdNoticeKind.permission,
            outcome: XswdChoiceOutcome.allowed,
            scope: XswdChoiceScope.request,
            subscriptionEvent: WalletEvent.balanceChanged,
            methods: const ['subscribe'],
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
    final theme = greenDark(touch: true);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
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
    expect(
      find.byKey(const ValueKey('xswd-observation-warning')),
      findsNothing,
    );
    final recentTab = find.text(loc.xswd_recent_choices_title);
    await tester.ensureVisible(recentTab);
    await tester.tap(recentTab);
    await tester.pumpAndSettle();

    final subscribeTitle = xswdPermissionCopy(
      'subscribe',
      tryXswdMethodPolicyForKey('subscribe'),
      loc,
    ).title;
    final subscriptionChoiceTitle = loc.xswd_recent_allowed_once(
      subscribeTitle,
    );
    final prefetchTitle = loc.xswd_recent_prefetch_allowed(1);
    expect(find.text(subscriptionChoiceTitle), findsOneWidget);
    expect(
      find.text(
        loc.xswd_recent_event(
          xswdWalletEventLabel(WalletEvent.balanceChanged, loc),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text(loc.xswd_recent_rule_unchanged), findsOneWidget);
    expect(find.text(prefetchTitle), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(subscriptionChoiceTitle)).dy,
      lessThan(tester.getTopLeft(find.text(prefetchTitle)).dy),
    );
    final prefetchTile = find.ancestor(
      of: find.text(prefetchTitle),
      matching: find.byType(FTile),
    );
    expect(
      find.descendant(of: prefetchTile, matching: find.byType(FBadge)),
      findsNothing,
    );
    await tester.ensureVisible(prefetchTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: prefetchTile, matching: find.text(loc.more_details)),
    );
    await tester.pumpAndSettle();
    final granted = find.byKey(const ValueKey('xswd-choice-granted-methods'));
    final unchanged = find.byKey(
      const ValueKey('xswd-choice-unchanged-methods'),
    );
    final balanceTitle = xswdPermissionCopy(
      'get_balance',
      tryXswdMethodPolicyForKey('get_balance'),
      loc,
    ).title;
    expect(
      find.descendant(of: granted, matching: find.textContaining(balanceTitle)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: granted,
        matching: find.textContaining(subscribeTitle),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: unchanged,
        matching: find.textContaining(subscribeTitle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: unchanged,
        matching: find.textContaining(balanceTitle),
      ),
      findsNothing,
    );
    expect(find.text(loc.xswd_permission_status_allowed), findsNothing);
    final foreignMethodTitle = xswdPermissionCopy(
      'network_info',
      tryXswdMethodPolicyForKey('network_info'),
      loc,
    ).title;
    expect(find.textContaining(foreignMethodTitle), findsNothing);
    expect(find.text(loc.xswd_recent_choices_disclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'recent outcomes distinguish one-time choices and connection rules',
    (tester) async {
      final loc = AppLocalizationsEn();
      final app = XelisXswdApplication(
        id: 'fictional-outcomes',
        name: 'Fictional vault',
        description: '',
        url: null,
        permissions: const {},
        isRelayer: false,
      );
      final title = xswdPermissionCopy(
        'get_address',
        tryXswdMethodPolicyForKey('get_address'),
        loc,
      ).title;
      final cases = [
        (
          kind: XswdNoticeKind.permission,
          outcome: XswdChoiceOutcome.refused,
          scope: XswdChoiceScope.request,
          label: loc.xswd_recent_refused_once(title),
        ),
        (
          kind: XswdNoticeKind.permission,
          outcome: XswdChoiceOutcome.allowed,
          scope: XswdChoiceScope.connection,
          label: loc.xswd_recent_allowed_connection(title),
        ),
        (
          kind: XswdNoticeKind.permission,
          outcome: XswdChoiceOutcome.refused,
          scope: XswdChoiceScope.connection,
          label: loc.xswd_recent_blocked_connection(title),
        ),
        (
          kind: XswdNoticeKind.prefetch,
          outcome: XswdChoiceOutcome.unchanged,
          scope: XswdChoiceScope.connection,
          label: loc.xswd_recent_unchanged,
        ),
        (
          kind: XswdNoticeKind.prefetch,
          outcome: XswdChoiceOutcome.expired,
          scope: XswdChoiceScope.connection,
          label: loc.xswd_recent_request_expired,
        ),
        (
          kind: XswdNoticeKind.permission,
          outcome: XswdChoiceOutcome.cancelled,
          scope: XswdChoiceScope.connection,
          label: loc.xswd_recent_request_cancelled,
        ),
        (
          kind: XswdNoticeKind.application,
          outcome: XswdChoiceOutcome.allowed,
          scope: XswdChoiceScope.connection,
          label: loc.xswd_recent_connection_allowed,
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(loc),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en')),
          ),
          xswdApplicationsProvider.overrideWith((ref) async => [app]),
        ],
      );
      addTearDown(container.dispose);
      for (final entry in cases) {
        container
            .read(xswdRecentChoicesProvider.notifier)
            .record(
              XswdRecentChoice(
                sessionReference: app.sessionReference,
                kind: entry.kind,
                outcome: entry.outcome,
                scope: entry.scope,
                methods: const ['get_address'],
              ),
            );
      }
      final theme = greenDark(touch: false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme.toApproximateMaterialTheme(),
            home: GenesixTheme(
              data: theme,
              child: XswdAppDetail(sessionReference: app.sessionReference),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(loc.xswd_recent_choices_title));
      await tester.pumpAndSettle();
      for (final entry in cases) {
        final label = find.text(entry.label);
        expect(label, findsOneWidget);
        final tile = find.ancestor(of: label, matching: find.byType(FTile));
        expect(
          find.descendant(of: tile, matching: find.byType(FBadge)),
          findsNothing,
        );
        if (entry.outcome == XswdChoiceOutcome.expired ||
            entry.outcome == XswdChoiceOutcome.cancelled) {
          expect(
            find.descendant(of: tile, matching: find.byType(FAccordion)),
            findsNothing,
          );
          expect(
            find.descendant(
              of: tile,
              matching: find.text(loc.xswd_scope_connection),
            ),
            findsNothing,
          );
        }
      }
      expect(find.text(loc.xswd_recent_rule_unchanged), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
