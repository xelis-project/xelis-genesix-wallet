import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_lifecycle_provider.dart';
import 'package:genesix/features/wallet/application/xswd_notification_service.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/domain/xswd_lifecycle_state.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart'
    show BurnBuilder, FixedFeeBuilder, parseBigIntJson;

import '../../../helpers/xswd_test_payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final outcome in [
    'accept',
    'alwaysAccept',
    'reject',
    'cancel',
    'replace',
    'close',
    'close-replace',
    'close-other',
  ]) {
    test('typed request stays bound through $outcome', () async {
      final repository = _FakeNativeWalletRepository('a');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repository));
      expect(
        await container.read(xswdControllerProvider).startXSWD(repository),
        isTrue,
      );
      final request = XelisXswdRequest(
        kind: XelisXswdRequestKind.permission,
        application: _application,
        payload: xswdTestPayload(
          parseBigIntJson(
            '{"id":18446744073709551615,"jsonrpc":"2.0",'
            '"method":"build_transaction","params":{'
            '"burn":{"asset":"asset-hash","amount":9007199254740993},'
            '"nonce":18446744073709551615,"fee":{"fixed":9007199254740993}}}',
          ),
        ),
      );
      final callbacks = repository.callbacks!;
      final result = Future<XelisXswdDecision>.value(
        callbacks.onPermissionRequest(request),
      );
      final state = container.read(xswdRequestProvider);
      expect(identical(state.xswdEventSummary, request), isTrue);
      expect(
        state.permissionReview!.buildTransactionParams!.nonce,
        (BigInt.one << 64) - BigInt.one,
      );
      final reviewed = state.permissionReview!.buildTransactionParams!;
      expect(
        (reviewed.transactionTypeBuilder as BurnBuilder).amount,
        BigInt.parse('9007199254740993'),
      );
      expect(
        (reviewed.fee as FixedFeeBuilder).amount,
        BigInt.parse('9007199254740993'),
      );
      expect(state.decision!.isCompleted, isFalse);

      if (outcome == 'close' || outcome == 'close-replace') {
        final closeGate = Completer<void>();
        repository.removeGate = closeGate;
        final close = container
            .read(xswdControllerProvider)
            .closeXswdAppConnection(_application);
        expect(state.decision!.isCompleted, isTrue);
        expect(await result, XelisXswdDecision.reject);
        expect(container.read(xswdRequestProvider).decision, isNull);
        expect(repository.removedApplications, [_application.sessionReference]);
        // A late callback from the closing transport cannot reopen consent.
        expect(
          await callbacks.onPermissionRequest(request),
          XelisXswdDecision.reject,
        );
        expect(container.read(xswdRequestProvider).decision, isNull);
        final effects = <WalletEffectEnvelope?>[];
        final subscription = container.listen(
          walletEffectBusProvider,
          (_, next) => effects.add(next),
        );
        addTearDown(subscription.close);
        if (outcome == 'close-replace') {
          container
              .read(activeWalletSessionProvider.notifier)
              .setSession(
                WalletSession(
                  name: 'b',
                  repository: _FakeNativeWalletRepository('b'),
                ),
              );
        }
        closeGate.complete();
        await close;
        if (outcome == 'close-replace') expect(effects, isEmpty);
      } else if (outcome == 'close-other') {
        await container
            .read(xswdControllerProvider)
            .closeXswdAppConnection(
              XelisXswdApplication(
                id: _application.id,
                name: 'Other app',
                description: '',
                url: null,
                permissions: const {},
                isRelayer: false,
              ),
            );
        expect(state.decision!.isCompleted, isFalse);
        expect(
          identical(
            container.read(xswdRequestProvider).decision,
            state.decision,
          ),
          isTrue,
        );
        state.decision!.complete(XelisXswdDecision.accept);
      } else if (outcome == 'cancel') {
        await callbacks.onCancelRequest(
          XelisXswdRequest(
            kind: XelisXswdRequestKind.cancel,
            application: _application,
          ),
        );
      } else {
        if (outcome == 'replace') {
          container
              .read(activeWalletSessionProvider.notifier)
              .setSession(
                WalletSession(
                  name: 'b',
                  repository: _FakeNativeWalletRepository('b'),
                ),
              );
        }
        state.decision!.complete(switch (outcome) {
          'reject' => XelisXswdDecision.reject,
          'alwaysAccept' => XelisXswdDecision.alwaysAccept,
          _ => XelisXswdDecision.accept,
        });
      }
      expect(await result, switch (outcome) {
        'accept' || 'alwaysAccept' || 'close-other' => XelisXswdDecision.accept,
        _ => XelisXswdDecision.reject,
      });
      container.read(xswdRequestProvider.notifier).clearRequest();
    });
  }

  test(
    'foreign lifecycle callbacks preserve the active session decision',
    () async {
      final repository = _FakeNativeWalletRepository('a');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repository));
      final controller = container.read(xswdControllerProvider);
      expect(await controller.startXSWD(repository), isTrue);
      final firstHandler = repository.callbacks!;
      expect(await controller.addXswdRelayer(repository, _relayer), isTrue);
      final secondHandler = repository.callbacks!;
      final otherApplication = XelisXswdApplication(
        id: _application.id,
        name: 'Other connection',
        description: '',
        url: null,
        permissions: const {},
        isRelayer: true,
      );
      final activeRequest = XelisXswdRequest(
        kind: XelisXswdRequestKind.permission,
        application: _application,
        payload: xswdTestPayload(
          parseBigIntJson(
            '{"jsonrpc":"2.0","id":1,"method":"get_balance",'
            '"params":{"asset":null}}',
          ),
        ),
      );
      final decision = Future<XelisXswdDecision>.value(
        firstHandler.onPermissionRequest(activeRequest),
      );
      final pending = container.read(xswdRequestProvider).decision!;

      for (final kind in [
        XelisXswdRequestKind.cancel,
        XelisXswdRequestKind.applicationDisconnect,
      ]) {
        final lifecycle = XelisXswdRequest(
          kind: kind,
          application: otherApplication,
        );
        if (kind == XelisXswdRequestKind.cancel) {
          await secondHandler.onCancelRequest(lifecycle);
        } else {
          await secondHandler.onApplicationDisconnect(lifecycle);
        }
        expect(pending.isCompleted, isFalse);
        expect(container.read(xswdRequestProvider).decision, same(pending));
        expect(
          container
              .read(xswdRequestProvider)
              .xswdEventSummary
              ?.application
              .sessionReference,
          _application.sessionReference,
        );
      }

      pending.complete(XelisXswdDecision.accept);
      expect(await decision, XelisXswdDecision.accept);
      container.read(xswdRequestProvider.notifier).clearRequest();
    },
  );

  test(
    'session replacement stops the origin before starting the successor',
    () async {
      final repositoryA = _FakeNativeWalletRepository('a');
      final repositoryB = _FakeNativeWalletRepository('b');
      final controller = _FakeXswdController();
      final container = _lifecycleContainer(controller);
      addTearDown(container.dispose);

      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repositoryA));
      container.listen(xswdLifecycleProvider, (_, _) {}, fireImmediately: true);
      await _waitUntil(() => controller.operations.contains('start:a'));

      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'b', repository: repositoryB));
      await _waitUntil(() => controller.operations.contains('start:b'));

      expect(
        controller.operations,
        containsAllInOrder(['start:a', 'stop:a', 'start:b']),
      );
      expect(container.read(xswdLifecycleProvider).isRunning, isTrue);
    },
  );

  test('stop wins over an in-flight relayer addition', () async {
    final repository = _FakeNativeWalletRepository('wallet');
    final controller = _FakeXswdController();
    final container = _lifecycleContainer(controller);
    addTearDown(container.dispose);

    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'wallet', repository: repository));
    container.listen(xswdLifecycleProvider, (_, _) {}, fireImmediately: true);
    await _waitUntil(() => controller.operations.contains('start:wallet'));

    final gate = Completer<void>();
    controller.addGate = gate;
    final lifecycle = container.read(xswdLifecycleProvider.notifier);
    final addFuture = lifecycle.addRelayer(_relayer);
    await _waitUntil(() => controller.operations.contains('add:wallet'));

    final stopFuture = lifecycle.stop();
    gate.complete();

    expect(await addFuture, isFalse);
    await stopFuture;
    expect(
      controller.operations.where((entry) => entry == 'stop:wallet'),
      isNotEmpty,
    );
    expect(
      container.read(xswdLifecycleProvider).phase,
      XswdLifecyclePhase.stopped,
    );
  });

  test(
    'offline reconciliation waits for an exact application close before stop',
    () async {
      final repository = _FakeNativeWalletRepository('wallet');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'wallet', repository: repository));
      container.listen(xswdLifecycleProvider, (_, _) {}, fireImmediately: true);
      await _waitUntil(() => repository.callbacks != null);

      final closeGate = Completer<void>();
      repository.removeGate = closeGate;
      final close = container
          .read(xswdControllerProvider)
          .closeXswdAppConnection(_application);
      await _waitUntil(() => repository.removedApplications.isNotEmpty);

      container.updateOverrides([
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
        settingsProvider.overrideWithValue(
          const SettingsState(
            locale: Locale('en'),
            enableXswd: true,
            walletOfflineMode: true,
          ),
        ),
        walletRuntimeProvider.overrideWithValue(_connectedRuntime),
        xswdNotificationServiceProvider.overrideWithValue(
          _FakeXswdNotificationService(),
        ),
      ]);
      await _waitUntil(
        () =>
            container.read(xswdLifecycleProvider).phase ==
            XswdLifecyclePhase.stopping,
      );
      expect(repository.stopCalls, 0);

      closeGate.complete();
      await close;
      await _waitUntil(() => repository.stopCalls == 1);
      await _waitUntil(
        () =>
            container.read(xswdLifecycleProvider).phase ==
            XswdLifecyclePhase.stopped,
      );
      expect(repository.stopCalls, 1);
    },
  );

  test(
    'application close follows a successful active repository stop',
    () async {
      final repository = _FakeNativeWalletRepository('wallet');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'wallet', repository: repository));
      final stopGate = Completer<void>();
      repository.stopGate = stopGate;

      final controller = container.read(xswdControllerProvider);
      final stop = controller.stopXSWD(repository);
      await _waitUntil(() => repository.stopCalls == 1);
      final close = controller.closeXswdAppConnection(_application);

      expect(repository.removedApplications, isEmpty);
      stopGate.complete();
      expect(await stop, isTrue);
      await close;
      expect(repository.removedApplications, isEmpty);
    },
  );

  test(
    'application close retries exactly after an active stop fails',
    () async {
      final repository = _FakeNativeWalletRepository('wallet');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'wallet', repository: repository));
      final stopGate = Completer<void>();
      repository
        ..stopGate = stopGate
        ..stopError = StateError('stop failed');

      final controller = container.read(xswdControllerProvider);
      final stop = controller.stopXSWD(repository);
      await _waitUntil(() => repository.stopCalls == 1);
      final close = controller.closeXswdAppConnection(_application);

      expect(repository.removedApplications, isEmpty);
      stopGate.complete();
      expect(await stop, isFalse);
      await close;
      expect(repository.removedApplications, [_application.sessionReference]);
    },
  );

  test(
    'deferred close for a replaced repository has no successor UI effect',
    () async {
      final repositoryA = _FakeNativeWalletRepository('a');
      final repositoryB = _FakeNativeWalletRepository('b');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repositoryA));
      final effects = <WalletEffectEnvelope?>[];
      final subscription = container.listen(
        walletEffectBusProvider,
        (_, next) => effects.add(next),
      );
      addTearDown(subscription.close);
      final stopGate = Completer<void>();
      final closeGate = Completer<void>();
      repositoryA
        ..stopGate = stopGate
        ..stopError = StateError('stop failed')
        ..removeGate = closeGate;

      final controller = container.read(xswdControllerProvider);
      final stop = controller.stopXSWD(repositoryA);
      await _waitUntil(() => repositoryA.stopCalls == 1);
      final close = controller.closeXswdAppConnection(_application);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'b', repository: repositoryB));

      stopGate.complete();
      expect(await stop, isFalse);
      await _waitUntil(() => repositoryA.removedApplications.isNotEmpty);
      final effectsAfterStop = effects.length;
      closeGate.complete();
      await close;

      expect(repositoryA.removedApplications, [_application.sessionReference]);
      expect(effects, hasLength(effectsAfterStop));
      expect(
        container.read(activeWalletSessionProvider)?.repository,
        same(repositoryB),
      );
    },
  );

  test(
    'callbacks reject stale sessions and report malformed payload once',
    () async {
      final repositoryA = _FakeNativeWalletRepository('a');
      final repositoryB = _FakeNativeWalletRepository('b');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repositoryA));

      final effects = <WalletEffect>[];
      container.listen<WalletEffectEnvelope?>(walletEffectBusProvider, (
        _,
        next,
      ) {
        if (next != null) effects.add(next.effect);
      });
      final controller = container.read(xswdControllerProvider);
      expect(await controller.startXSWD(repositoryA), isTrue);
      final callbacks = repositoryA.callbacks!;
      repositoryA
        ..xswdApplications = [_application]
        ..xswdStateReads = 0
        ..requireStateReadBeforeRemove = true;

      final malformedDecision = await Future<XelisXswdDecision>.value(
        callbacks.onPermissionRequest(
          XelisXswdRequest(
            kind: XelisXswdRequestKind.permission,
            application: _application,
            payload: const XelisXswdStringValue('invalid-root'),
          ),
        ),
      );
      expect(malformedDecision, XelisXswdDecision.reject);
      expect(repositoryA.removedApplications, isEmpty);
      await _waitUntil(() => repositoryA.removedApplications.isNotEmpty);
      expect(repositoryA.removedApplications, [_application.sessionReference]);
      expect(repositoryA.xswdStateReads, 1);
      expect(effects.whereType<WalletFailureEffect>(), hasLength(1));

      container.read(xswdRequestProvider.notifier).clearRequest();
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'b', repository: repositoryB));
      final staleDecision = await Future<XelisXswdDecision>.value(
        callbacks.onApplicationRequest(
          XelisXswdRequest(
            kind: XelisXswdRequestKind.application,
            application: _application,
          ),
        ),
      );

      expect(staleDecision, XelisXswdDecision.reject);
      expect(container.read(xswdRequestProvider).xswdEventSummary, isNull);
      expect(effects.whereType<WalletFailureEffect>(), hasLength(1));
    },
  );
}

ProviderContainer _lifecycleContainer(_FakeXswdController controller) {
  return ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      settingsProvider.overrideWithValue(
        const SettingsState(locale: Locale('en'), enableXswd: true),
      ),
      walletRuntimeProvider.overrideWithValue(_connectedRuntime),
      xswdControllerProvider.overrideWithValue(controller),
      xswdNotificationServiceProvider.overrideWithValue(
        _FakeXswdNotificationService(),
      ),
    ],
  );
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Timed out waiting for the expected XSWD transition');
}

final _connectedRuntime = WalletRuntimeState(
  isOnline: true,
  connectionPhase: WalletConnectionPhase.connected,
  address: 'wallet-address',
  network: XelisNetwork.mainnet,
  topoheight: BigInt.zero,
  xelisBalance: BigInt.zero,
  trackedBalances: LinkedHashMap(),
  knownAssets: LinkedHashMap(),
);

final _application = XelisXswdApplication(
  id: 'app-id',
  name: 'Test app',
  description: 'Test application',
  url: null,
  permissions: const {},
  isRelayer: false,
);

final _relayer = XelisXswdRelayer(
  id: 'app-id',
  name: 'Test app',
  description: 'Test application',
  url: null,
  permissions: const [],
  relayer: 'wss://relay.example.test/session',
);

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  _FakeNativeWalletRepository(this.label);

  final String label;
  XelisXswdCallbacks? callbacks;
  List<XelisXswdApplication> xswdApplications = const [];
  final List<XelisXswdSessionReference> removedApplications = [];
  Completer<void>? removeGate;
  Completer<void>? stopGate;
  Object? stopError;
  int stopCalls = 0;
  int xswdStateReads = 0;
  bool requireStateReadBeforeRemove = false;

  @override
  String get address => 'wallet-address';

  @override
  XelisNetwork get network => XelisNetwork.mainnet;

  @override
  Future<void> startXSWD({required XelisXswdCallbacks callbacks}) async {
    this.callbacks = callbacks;
  }

  @override
  Future<XelisXswdState> getXswdState() async {
    xswdStateReads++;
    return XelisXswdState(
      isRunning: false,
      applications: List.unmodifiable(xswdApplications),
    );
  }

  @override
  Future<void> stopXSWD() async {
    stopCalls++;
    await stopGate?.future;
    final error = stopError;
    if (error != null) throw error;
  }

  @override
  Future<void> addXswdRelayer({
    required XelisXswdCallbacks callbacks,
    required XelisXswdRelayer relayerData,
  }) async {
    this.callbacks = callbacks;
  }

  @override
  Future<void> removeXswdApp(XelisXswdApplication application) async {
    if (requireStateReadBeforeRemove && xswdStateReads == 0) {
      throw StateError('fresh XSWD state was not read before removal');
    }
    removedApplications.add(application.sessionReference);
    await removeGate?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeXswdController implements XswdController {
  final List<String> operations = [];
  Completer<void>? addGate;

  @override
  Future<bool> startXSWD(NativeWalletRepository repository) async {
    operations.add(
      'start:${(repository as _FakeNativeWalletRepository).label}',
    );
    return true;
  }

  @override
  Future<bool> stopXSWD(NativeWalletRepository repository) async {
    operations.add('stop:${(repository as _FakeNativeWalletRepository).label}');
    return true;
  }

  @override
  Future<bool> addXswdRelayer(
    NativeWalletRepository repository,
    XelisXswdRelayer relayerData,
  ) async {
    operations.add('add:${(repository as _FakeNativeWalletRepository).label}');
    final gate = addGate;
    if (gate != null) await gate.future;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeXswdNotificationService extends XswdNotificationService {
  _FakeXswdNotificationService() : super(onApprovalOpen: () {});

  @override
  Future<void> sync({required bool active, required String title}) async {}

  @override
  Future<void> showPendingApproval({
    required String title,
    required String appName,
    required String body,
    required Object owner,
  }) async {}

  @override
  Future<void> clearPendingApproval({Object? owner}) async {}
}
