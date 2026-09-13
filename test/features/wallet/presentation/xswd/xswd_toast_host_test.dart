import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/xswd_decision_timing.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_toast_host.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/resources/localizations.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/toaster_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('keeps approval visible until the dialog acknowledges it', (
    tester,
  ) async {
    final harness = await _pumpHost(tester);
    final notice = _beginRequest(harness, 'Example dApp');

    await tester.pumpAndSettle();

    expect(find.text('Example dApp'), findsOneWidget);
    expect(find.text(harness.localizations.connection_request), findsOneWidget);
    expect(find.text(harness.localizations.open_button), findsOneWidget);
    expect(find.text(harness.localizations.deny), findsOneWidget);
    expect(find.byIcon(FLucideIcons.x), findsNothing);

    await tester.tap(find.byKey(const ValueKey('xswd-toast-open')));
    await tester.pumpAndSettle();

    expect(find.text('Example dApp'), findsOneWidget);
    expect(
      identical(
        harness.container.read(xswdDialogCoordinatorProvider).intent?.token,
        notice.token,
      ),
      isTrue,
    );

    harness.container
        .read(xswdDialogCoordinatorProvider.notifier)
        .markPresented(notice.token);
    await tester.pumpAndSettle();

    expect(find.text('Example dApp'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stale approval action cannot reject its replacement', (
    tester,
  ) async {
    final harness = await _pumpHost(tester);
    final noticeA = _beginRequest(harness, 'Application A');
    await tester.pumpAndSettle();
    final staleDeny = tester
        .widget<FButton>(find.byKey(const ValueKey('xswd-toast-deny')))
        .onPress;

    final noticeB = _beginRequest(harness, 'Application B');
    await tester.pumpAndSettle();
    staleDeny?.call();
    await tester.pumpAndSettle();

    final state = harness.container.read(xswdRequestProvider);
    expect(identical(state.token, noticeA.token), isFalse);
    expect(identical(state.token, noticeB.token), isTrue);
    expect(state.pending, isTrue);
    expect(find.text('Application A'), findsNothing);
    expect(find.text('Application B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary information does not replace an approval', (
    tester,
  ) async {
    final harness = await _pumpHost(tester);
    final notice = _beginRequest(harness, 'Application B');
    await tester.pumpAndSettle();

    harness.container
        .read(toastProvider.notifier)
        .showInformation(title: 'Application A cancelled');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Application A cancelled'), findsOneWidget);
    expect(find.text('Application B'), findsOneWidget);
    expect(
      identical(
        harness.container.read(xswdRequestProvider).token,
        notice.token,
      ),
      isTrue,
    );
    expect(harness.container.read(xswdRequestProvider).pending, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coalesces requests emitted before the next frame', (
    tester,
  ) async {
    final harness = await _pumpHost(tester);
    _beginRequest(harness, 'Application A');
    final noticeB = _beginRequest(harness, 'Application B');

    await tester.pumpAndSettle();

    expect(find.text('Application A'), findsNothing);
    expect(find.text('Application B'), findsOneWidget);
    expect(
      identical(
        harness.container.read(xswdRequestProvider).token,
        noticeB.token,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('can unmount while the deferred dismissal is pending', (
    tester,
  ) async {
    final harness = await _pumpHost(tester);
    final notice = _beginRequest(harness, 'Pending permission');
    await tester.pump();

    harness.container
        .read(xswdDialogCoordinatorProvider.notifier)
        .markPresented(notice.token);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('stale callbacks are inert after only the host unmounts', (
    tester,
  ) async {
    final harness = await _pumpHost(tester);
    _beginRequest(harness, 'Pending permission');
    await tester.pumpAndSettle();
    final open = tester
        .widget<FButton>(find.byKey(const ValueKey('xswd-toast-open')))
        .onPress;
    final deny = tester
        .widget<FButton>(find.byKey(const ValueKey('xswd-toast-deny')))
        .onPress;

    await tester.pumpWidget(
      _buildApp(
        container: harness.container,
        theme: harness.theme,
        child: const SizedBox.expand(),
      ),
    );
    open?.call();
    deny?.call();
    await tester.pumpAndSettle();

    expect(harness.container.read(xswdRequestProvider).pending, isTrue);
    expect(find.byKey(const ValueKey('xswd-approval-toast')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps both approval actions usable at narrow width', (
    tester,
  ) async {
    final harness = await _pumpHost(
      tester,
      size: const Size(320, 480),
      textScale: 2,
    );
    _beginRequest(harness, 'An application with a very long display name');

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('xswd-toast-open')), findsOneWidget);
    expect(find.byKey(const ValueKey('xswd-toast-deny')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

XswdNotice _beginRequest(_HostHarness harness, String applicationName) {
  final application = XelisXswdApplication(
    id: applicationName,
    name: applicationName,
    description: 'Test application',
    url: null,
    permissions: const {},
    isRelayer: false,
  );
  harness.container
      .read(xswdRequestProvider.notifier)
      .newRequest(
        xswdEventSummary: XelisXswdRequest(
          kind: XelisXswdRequestKind.application,
          application: application,
        ),
        message: 'Connection request',
        repository: harness.repository,
      );
  final notice = harness.container
      .read(xswdRequestProvider.notifier)
      .currentNotice!;
  harness.container
      .read(walletEffectBusProvider.notifier)
      .emit(WalletEffect.xswd(notice: notice));
  return notice;
}

Future<_HostHarness> _pumpHost(
  WidgetTester tester, {
  Size size = const Size(420, 700),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final localizations = AppLocalizationsEn();
  final repository = _FakeNativeWalletRepository();
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(localizations),
      xswdDecisionClockProvider.overrideWithValue(
        const _InertXswdDecisionClock(),
      ),
    ],
  );
  addTearDown(container.dispose);
  container
      .read(activeWalletSessionProvider.notifier)
      .setSession(WalletSession(name: 'test', repository: repository));
  final theme = greenDark(touch: false);

  await tester.pumpWidget(
    _buildApp(
      container: container,
      theme: theme,
      textScale: textScale,
      child: const XswdToastHost(child: SizedBox.expand()),
    ),
  );
  await tester.pump();

  return _HostHarness(
    container: container,
    localizations: localizations,
    repository: repository,
    theme: theme,
  );
}

final class _InertXswdDecisionClock implements XswdDecisionClock {
  const _InertXswdDecisionClock();

  @override
  Duration now() => Duration.zero;

  @override
  XswdScheduledTask schedule(Duration delay, void Function() callback) {
    return _InertXswdScheduledTask();
  }
}

final class _InertXswdScheduledTask implements XswdScheduledTask {
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  void cancel() => _active = false;
}

Widget _buildApp({
  required ProviderContainer container,
  required FThemeData theme,
  required Widget child,
  double textScale = 1,
}) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: theme.toApproximateMaterialTheme(),
    localizationsDelegates: genesixLocalizationsDelegates,
    locale: const Locale('en'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: GenesixTheme(
      data: theme,
      child: ToasterWidget(child: child),
    ),
  ),
);

class _HostHarness {
  const _HostHarness({
    required this.container,
    required this.localizations,
    required this.repository,
    required this.theme,
  });

  final ProviderContainer container;
  final AppLocalizationsEn localizations;
  final _FakeNativeWalletRepository repository;
  final FThemeData theme;
}

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  @override
  String get address => 'wallet-address';

  @override
  XelisNetwork get network => XelisNetwork.mainnet;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
