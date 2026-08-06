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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      final malformedDecision = await Future<XelisXswdDecision>.value(
        callbacks.onPermissionRequest(
          XelisXswdRequest(
            kind: XelisXswdRequestKind.permission,
            application: _application,
            payloadJson: '{not-json',
          ),
        ),
      );
      expect(malformedDecision, XelisXswdDecision.reject);
      expect(repositoryA.removedApplicationIds, ['app-id']);
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
  final List<String> removedApplicationIds = [];

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
    return XelisXswdState(isRunning: false, applications: const []);
  }

  @override
  Future<void> stopXSWD() async {}

  @override
  Future<void> addXswdRelayer({
    required XelisXswdCallbacks callbacks,
    required XelisXswdRelayer relayerData,
  }) async {
    this.callbacks = callbacks;
  }

  @override
  Future<void> removeXswdApp(String appID) async {
    removedApplicationIds.add(appID);
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
