import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog_host.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_toast_host.dart';
import 'package:genesix/shared/resources/localizations.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/toaster_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets(
      'opens a real dialog and preserves an unseen successor after back (reduced motion: $reducedMotion)',
      (tester) async {
        final harness = await _pumpApp(tester, reducedMotion: reducedMotion);
        final first = harness.begin('A');
        final notifier = harness.container.read(xswdRequestProvider.notifier);
        final tokenA = harness.container.read(xswdRequestProvider).token!;
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('xswd-toast-open')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('xswd-toast-open')));
        await tester.pumpAndSettle();
        expect(find.byType(XswdDialog), findsOneWidget);
        expect(
          harness.container.read(xswdDialogCoordinatorProvider).presentedToken,
          same(tokenA),
        );
        expect(find.byKey(const ValueKey('xswd-toast-open')), findsNothing);

        // Back closes A. Install B before the old route's completion is delivered.
        routerKey.currentState!.pop();
        final second = harness.begin('B');
        final tokenB = harness.container.read(xswdRequestProvider).token!;
        await tester.pumpAndSettle();
        expect(await first, XelisXswdDecision.reject);
        expect(harness.container.read(xswdRequestProvider).token, same(tokenB));
        expect(harness.container.read(xswdRequestProvider).pending, isTrue);
        expect(find.byKey(const ValueKey('xswd-toast-open')), findsOneWidget);
        expect(notifier.rejectIfCurrent(tokenB), isTrue);
        expect(await second, XelisXswdDecision.reject);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'unmounts the hosts during the 500ms handover without provider mutations during dispose',
    (tester) async {
      final harness = await _pumpApp(tester);
      final decision = harness.begin('A');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('xswd-toast-open')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(harness.loc.allow));
      await tester.pump();
      expect(await decision, XelisXswdDecision.accept);
      await tester.pump();
      expect(
        find.text(harness.loc.xswd_connection_approved('A')),
        findsOneWidget,
      );
      expect(find.text(harness.loc.app_connected_title('A')), findsNothing);
      expect(
        harness.container.read(xswdRequestProvider).suppressXswdToast,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 150));
      expect(harness.container.read(xswdRequestProvider).token, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('closes a displayed request after exact-session cancellation', (
    tester,
  ) async {
    final harness = await _pumpApp(tester);
    final decision = harness.begin('A');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('xswd-toast-open')));
    await tester.pumpAndSettle();
    final token = harness.container.read(xswdRequestProvider).token!;
    harness.container.read(xswdRequestProvider.notifier).clearIfCurrent(token);
    await tester.pumpAndSettle();
    expect(await decision, XelisXswdDecision.reject);
    expect(find.byType(XswdDialog), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<_Harness> _pumpApp(
  WidgetTester tester, {
  bool reducedMotion = false,
}) async {
  final repository = _Repository();
  final loc = AppLocalizationsEn();
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(loc),
      settingsProvider.overrideWithValue(
        const SettingsState(locale: Locale('en')),
      ),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(activeWalletSessionProvider.notifier)
      .setSession(WalletSession(name: 'test', repository: repository));
  final router = GoRouter(
    navigatorKey: routerKey,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.expand()),
    ],
  );
  addTearDown(router.dispose);
  final theme = greenDark(touch: false);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme.toApproximateMaterialTheme(),
        localizationsDelegates: genesixLocalizationsDelegates,
        locale: const Locale('en'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: GenesixTheme(
            data: theme,
            child: ToasterWidget(
              child: XswdToastHost(child: XswdDialogHost(child: child!)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(container, repository, loc);
}

class _Harness {
  _Harness(this.container, this.repository, this.loc);
  final ProviderContainer container;
  final NativeWalletRepository repository;
  final AppLocalizationsEn loc;

  Future<XelisXswdDecision> begin(String name) => container
      .read(xswdRequestProvider.notifier)
      .newRequest(
        xswdEventSummary: XelisXswdRequest(
          kind: XelisXswdRequestKind.application,
          application: XelisXswdApplication(
            id: name,
            name: name,
            description: '',
            url: null,
            permissions: const {},
            isRelayer: false,
          ),
        ),
        message: '',
        repository: repository,
      );
}

class _Repository implements NativeWalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
