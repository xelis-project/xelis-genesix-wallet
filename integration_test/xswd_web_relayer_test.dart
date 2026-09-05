import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_lifecycle_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const _controlOrigin = String.fromEnvironment('GENESIX_XSWD_E2E_CONTROL');
const _applicationId =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _applicationName = 'Genesix Web E2E';
final _aboveJavaScriptSafeInteger = BigInt.parse('9007199254740993');
final _wideNonce = BigInt.parse('9007199254740995');
final _maximumUnsigned64 = BigInt.parse('18446744073709551615');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('binds real Web relay requests to Genesix review decisions', (
    tester,
  ) async {
    binding.reportData = {'phase': 'initialize'};
    expect(kIsWeb, isTrue, reason: 'The XSWD relay test is Web-only.');
    expect(
      _controlOrigin,
      isNotEmpty,
      reason: 'Run this test through tool/run_xswd_web_e2e.dart.',
    );

    await XelisWalletFlutter.initialize();
    expect(XelisWalletFlutter.isInitialized, isTrue);

    final runId = DateTime.now().microsecondsSinceEpoch;
    binding.reportData!['phase'] = 'create_wallet_a';
    final repositoryA = await NativeWalletRepository.create(
      'genesix-xswd-web-e2e-a-$runId',
      'fixture-password-a',
      XelisNetwork.mainnet,
      precomputedTableType: const XelisPrecomputedTableType.custom(16),
    );
    addTearDown(() => _closeFixtureRepository(repositoryA));
    binding.reportData!['phase'] = 'create_wallet_b';
    final repositoryB = await NativeWalletRepository.create(
      'genesix-xswd-web-e2e-b-$runId',
      'fixture-password-b',
      XelisNetwork.mainnet,
      precomputedTableType: const XelisPrecomputedTableType.custom(16),
    );
    addTearDown(() => _closeFixtureRepository(repositoryB));
    final loc = AppLocalizationsEn();
    final fixtureRuntime = _FixtureWalletRuntime(repositoryA.address);
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(loc),
        settingsProvider.overrideWithValue(
          const SettingsState(locale: Locale('en'), enableXswd: true),
        ),
        walletRuntimeProvider.overrideWith(() => fixtureRuntime),
      ],
    );
    addTearDown(container.dispose);
    final control = _XswdFixtureControl(_controlOrigin);
    final controller = container.read(xswdControllerProvider);
    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'fixture-a', repository: repositoryA));

    var repositoryAStopped = false;
    var repositoryBStopped = false;
    try {
      binding.reportData!['phase'] = 'admit_session_a';
      final lifecycle = container.read(xswdLifecycleProvider.notifier);
      await _waitForLifecycleRunning(tester, container);
      final connectedA = lifecycle.addRelayer(_relayer(control.relayerUrl));
      await _waitForRequest(
        tester,
        container,
        XelisXswdRequestKind.application,
      );
      await _decide(tester, container, label: loc.allow);
      expect(await connectedA, isTrue);
      await control.waitUntilRegistered(tester);

      await control.send('reject-transfer');
      final rejectedReview = await _waitForBuildTransaction(tester, container);
      _expectTransferReview(rejectedReview);
      await _decide(tester, container, label: loc.deny);
      final rejected = await control.waitForResponse(tester, 'reject-transfer');
      expect(rejected.hasError, isTrue);
      expect(rejected.errorKind, 'PERMISSION_DENIED');

      await control.send('approve-invoke');
      final approvedReview = await _waitForBuildTransaction(tester, container);
      _expectInvokeReview(approvedReview);
      await _pumpDialog(tester, container);
      expect(
        find.textContaining('9,007,199,254,740,993', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('18,446,744,073,709,551,615', findRichText: true),
        findsWidgets,
      );
      await _tapDecision(tester, loc.xswd_allow_once);
      final approved = await control.waitForResponse(tester, 'approve-invoke');
      expect(approved.hasError, isTrue);
      expect(
        approved.errorKind,
        'NOT_ONLINE_MODE',
        reason: 'Allow must reach the offline native wallet RPC, not denial.',
      );

      await control.send('replace-session');
      binding.reportData!['phase'] = 'replace_session';
      await _waitForBuildTransaction(tester, container);
      final replacedDecision = container.read(xswdRequestProvider).decision!;
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(
            WalletSession(name: 'fixture-b', repository: repositoryB),
          );
      fixtureRuntime.useRepository(repositoryB);
      await _waitForNoPendingDecision(tester, container);
      expect(await replacedDecision.future, XelisXswdDecision.reject);
      await _waitForLifecycleRunning(tester, container);
      repositoryAStopped = true;
      final replaced = await control.waitForResponse(tester, 'replace-session');
      expect(replaced.hasError, isTrue);
      expect(replaced.errorKind, 'PERMISSION_DENIED');
      await control.waitUntilDisconnected(tester);

      final connectedB = lifecycle.addRelayer(_relayer(control.relayerUrl));
      binding.reportData!['phase'] = 'admit_session_b';
      await _waitForRequest(
        tester,
        container,
        XelisXswdRequestKind.application,
      );
      await _decide(tester, container, label: loc.allow);
      expect(await connectedB, isTrue);
      await control.waitUntilRegistered(tester);

      // The list waits for active decisions. Read it after admission, before
      // the next request, as the application-detail flow does.
      final applications = await container
          .read(xswdApplicationsProvider.future)
          .timeout(const Duration(seconds: 20));
      final application = applications.single;
      await control.send('cancel-transfer');
      binding.reportData!['phase'] = 'close_application';
      await _waitForBuildTransaction(tester, container);
      final pending = container.read(xswdRequestProvider);
      final cancelledDecision = pending.decision!;
      expect(
        application.sessionReference,
        pending.xswdEventSummary!.application.sessionReference,
      );
      final closeApplication = controller.closeXswdAppConnection(application);
      // Wallet-side cancellation is owned by the two repositories under test.
      // A peer-only close can still be observed late by the pinned upstream
      // relayer and is deliberately not claimed as an immediate guarantee.
      expect(
        cancelledDecision.isCompleted,
        isTrue,
        reason: 'Closing the application must reject before transport cleanup.',
      );
      expect(await cancelledDecision.future, XelisXswdDecision.reject);
      await closeApplication.timeout(const Duration(seconds: 20));
      expect(container.read(xswdRequestProvider).decision, isNull);
      await control.waitUntilDisconnected(tester);

      // Re-admit on wallet B without opening the application list. Automatic
      // malformed-request cleanup must obtain live authority by itself.
      binding.reportData!['phase'] = 'malformed_session';
      final connectedC = lifecycle.addRelayer(_relayer(control.relayerUrl));
      await _waitForRequest(
        tester,
        container,
        XelisXswdRequestKind.application,
      );
      await _decide(tester, container, label: loc.allow);
      expect(await connectedC, isTrue);
      await control.waitUntilRegistered(tester);
      await control.send('malformed-transfer');
      await control.waitUntilDisconnected(tester);
      expect(container.read(xswdRequestProvider).decision, isNull);
      expect((await repositoryB.getXswdState()).applications, isEmpty);

      await lifecycle.stop();
      expect(container.read(xswdLifecycleProvider).hasFailed, isFalse);
      repositoryBStopped = true;
    } finally {
      container.read(xswdRequestProvider.notifier).clearRequest();
      if (!repositoryAStopped) {
        await controller
            .stopXSWD(repositoryA)
            .timeout(const Duration(seconds: 20));
      }
      if (!repositoryBStopped) {
        await controller
            .stopXSWD(repositoryB)
            .timeout(const Duration(seconds: 20));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

Future<void> _closeFixtureRepository(NativeWalletRepository repository) async {
  try {
    await repository.stopXSWD().timeout(const Duration(seconds: 20));
  } finally {
    try {
      await repository.close();
    } finally {
      repository.dispose();
    }
  }
}

WalletRuntimeState _connectedRuntime(String address) => WalletRuntimeState(
  isOnline: true,
  connectionPhase: WalletConnectionPhase.connected,
  address: address,
  network: XelisNetwork.mainnet,
  topoheight: BigInt.zero,
  xelisBalance: BigInt.zero,
  trackedBalances: LinkedHashMap(),
  knownAssets: LinkedHashMap(),
);

// Only the app's connectivity gate is controlled. Both native wallets remain
// offline: transport, XSWD callbacks, payload projection and RPC execution are
// real, but the fixture can never broadcast to a daemon.
final class _FixtureWalletRuntime extends WalletRuntime {
  _FixtureWalletRuntime(this.initialAddress);

  final String initialAddress;

  @override
  WalletRuntimeState build() => _connectedRuntime(initialAddress);

  void useRepository(NativeWalletRepository repository) {
    state = _connectedRuntime(repository.address);
  }
}

XelisXswdRelayer _relayer(String url) => XelisXswdRelayer(
  id: _applicationId,
  name: _applicationName,
  description: 'Ephemeral loopback integration fixture',
  url: null,
  permissions: const ['build_transaction'],
  relayer: url,
);

Future<void> _waitForRequest(
  WidgetTester tester,
  ProviderContainer container,
  XelisXswdRequestKind kind,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    await _waitForExternalEvents(tester, const Duration(milliseconds: 50));
    final request = container.read(xswdRequestProvider).xswdEventSummary;
    if (request?.kind == kind) {
      expect(request!.application.id, _applicationId);
      expect(request.application.name, _applicationName);
      return;
    }
  }
  fail('Timed out waiting for the ${kind.name} XSWD request.');
}

Future<XswdPermissionReview> _waitForBuildTransaction(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await _waitForRequest(tester, container, XelisXswdRequestKind.permission);
  final state = container.read(xswdRequestProvider);
  expect(
    state.permissionRpcRequest?.method,
    WalletMethod.buildTransaction.jsonKey,
  );
  final review = state.permissionReview;
  expect(review, isNotNull);
  expect(review!.isBuildTransaction, isTrue);
  expect(review.canPersist, isFalse);
  return review;
}

void _expectTransferReview(XswdPermissionReview review) {
  final params = review.buildTransactionParams!;
  final builder = params.transactionTypeBuilder as TransfersBuilder;
  expect(builder.transfers.single.amount, _aboveJavaScriptSafeInteger);
  expect((params.fee as FixedFeeBuilder).amount, _maximumUnsigned64);
  expect(params.feeLimit, _maximumUnsigned64);
  expect(params.nonce, _wideNonce);
}

void _expectInvokeReview(XswdPermissionReview review) {
  final params = review.buildTransactionParams!;
  final builder = params.transactionTypeBuilder as InvokeContractBuilder;
  expect(builder.maxGas, _aboveJavaScriptSafeInteger);
  expect(builder.deposits.values.single.amount, _aboveJavaScriptSafeInteger);
  expect((params.fee as FixedFeeBuilder).amount, _maximumUnsigned64);
  expect(params.feeLimit, _maximumUnsigned64);
  expect(params.nonce, _wideNonce);
}

Future<void> _decide(
  WidgetTester tester,
  ProviderContainer container, {
  required String label,
}) async {
  await _pumpDialog(tester, container);
  await _tapDecision(tester, label);
}

Future<void> _pumpDialog(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final theme = greenDark(touch: false);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
      GoRoute(
        path: '/review',
        pageBuilder: (_, _) => const NoTransitionPage<void>(
          child: Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: theme.toApproximateMaterialTheme(),
        builder: (_, child) => FTheme(data: theme, child: child!),
      ),
    ),
  );
  unawaited(router.push<void>('/review'));
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.byType(XswdDialog), findsOneWidget);
}

Future<void> _tapDecision(WidgetTester tester, String label) async {
  final action = find.text(label).hitTestable();
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _waitForNoPendingDecision(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await _waitForExternalEvents(tester, const Duration(milliseconds: 20));
    final state = container.read(xswdRequestProvider);
    if (state.decision == null && state.xswdEventSummary == null) {
      return;
    }
  }
  fail('Session replacement retained a pending XSWD decision.');
}

Future<void> _waitForLifecycleRunning(
  WidgetTester tester,
  ProviderContainer container,
) async {
  for (var attempt = 0; attempt < 400; attempt++) {
    await _waitForExternalEvents(tester, const Duration(milliseconds: 50));
    final state = container.read(xswdLifecycleProvider);
    expect(state.hasFailed, isFalse);
    if (state.isRunning) return;
  }
  fail('Timed out waiting for the XSWD lifecycle to reconcile the session.');
}

Future<void> _waitForExternalEvents(
  WidgetTester tester,
  Duration duration,
) async {
  // pump(Duration) advances fake widget time, not the WebSocket/WASM clock.
  await tester.runAsync(() => Future<void>.delayed(duration));
  await tester.pump();
}

final class _XswdFixtureControl {
  _XswdFixtureControl(String origin) : _origin = Uri.parse(origin);

  final Uri _origin;

  String get relayerUrl =>
      _origin.replace(scheme: 'ws', path: '/relay').toString();

  Future<void> send(String scenario) => _getEmpty('/send/$scenario');

  Future<void> disconnect() => _getEmpty('/disconnect');

  Future<void> waitUntilRegistered(WidgetTester tester) => _waitForState(
    tester,
    (state) => state['registered'] == true && state['connected'] == true,
    'relay registration',
  );

  Future<void> waitUntilDisconnected(WidgetTester tester) => _waitForState(
    tester,
    (state) =>
        state['connected'] == false && state['settled_disconnected'] == true,
    'relay disconnection',
  );

  Future<_RpcResponseState> waitForResponse(
    WidgetTester tester,
    String id,
  ) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      await _waitForExternalEvents(tester, const Duration(milliseconds: 50));
      final state = await _state();
      final responses = state['responses'] as Map<String, dynamic>;
      final response = responses[id];
      if (response is Map<String, dynamic>) {
        return _RpcResponseState(
          hasResult: response['has_result'] == true,
          hasError: response['has_error'] == true,
          errorCode: response['error_code'],
          errorKind: response['error_kind'],
        );
      }
    }
    fail('Timed out waiting for the sanitized $id relay response.');
  }

  Future<void> _waitForState(
    WidgetTester tester,
    bool Function(Map<String, dynamic>) predicate,
    String description,
  ) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      await _waitForExternalEvents(tester, const Duration(milliseconds: 50));
      final state = await _state();
      if (predicate(state)) return;
    }
    fail('Timed out waiting for $description.');
  }

  Future<Map<String, dynamic>> _state() async {
    final response = await http.get(_origin.replace(path: '/state'));
    expect(response.statusCode, 200);
    final decoded = jsonDecode(response.body);
    expect(decoded, isA<Map<String, dynamic>>());
    final state = decoded as Map<String, dynamic>;
    expect(
      state['failure'],
      isNull,
      reason: 'The relay fixture rejected a frame.',
    );
    return state;
  }

  Future<void> _getEmpty(String path) async {
    final response = await http.get(_origin.replace(path: path));
    expect(response.statusCode, anyOf(202, 204));
  }
}

final class _RpcResponseState {
  const _RpcResponseState({
    required this.hasResult,
    required this.hasError,
    required this.errorCode,
    required this.errorKind,
  });

  final bool hasResult;
  final bool hasError;
  final Object? errorCode;
  final Object? errorKind;
}
