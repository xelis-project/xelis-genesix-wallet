import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_notification_service.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/domain/xswd_lifecycle_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'xswd_lifecycle_provider.g.dart';

@Riverpod(keepAlive: true)
class XswdLifecycle extends _$XswdLifecycle {
  Future<void> _tail = Future.value();
  int _revision = 0;
  NativeWalletRepository? _activeRepository;
  WalletSession? _activeSession;

  @override
  XswdLifecycleState build() {
    ref.listen(
      settingsProvider.select(
        (settings) => (
          enableXswd: settings.enableXswd,
          walletOfflineMode: settings.walletOfflineMode,
        ),
      ),
      (_, _) => _scheduleReconciliation(),
    );
    ref.listen(
      activeWalletSessionProvider,
      (_, _) => _scheduleReconciliation(),
    );
    ref.listen(
      walletRuntimeProvider.select(
        (runtime) => (
          isOnline: runtime.isOnline,
          address: runtime.address,
          network: runtime.network,
        ),
      ),
      (_, _) => _scheduleReconciliation(),
    );

    Future.microtask(_scheduleReconciliation);
    return const XswdLifecycleState();
  }

  Future<void> stop() {
    final repository =
        _activeRepository ?? ref.read(activeWalletSessionProvider)?.repository;
    final revision = ++_revision;
    return _enqueue(() async {
      await _stop(
        repository: repository,
        revision: revision,
        desiredEnabled: false,
      );
    });
  }

  Future<bool> addRelayer(XelisXswdRelayer relayer) {
    final target = _readTarget();
    final revision = ++_revision;
    return _enqueue(() => _addRelayer(target, revision, relayer));
  }

  void _scheduleReconciliation() {
    if (!ref.mounted) {
      return;
    }

    final target = _readTarget();
    final revision = ++_revision;
    unawaited(_enqueue(() => _reconcile(target, revision)));
  }

  _XswdLifecycleTarget _readTarget() {
    final settings = ref.read(settingsProvider);
    final session = ref.read(activeWalletSessionProvider);
    final runtime = ref.read(walletRuntimeProvider);
    final sessionRuntimeMatches = _runtimeMatchesSession(runtime, session);

    return _XswdLifecycleTarget(
      desiredEnabled: settings.enableXswd && !settings.walletOfflineMode,
      session: session,
      repository: session?.repository,
      canRun: session != null && runtime.isOnline && sessionRuntimeMatches,
    );
  }

  bool _runtimeMatchesSession(
    WalletRuntimeState runtime,
    WalletSession? session,
  ) {
    return session != null &&
        runtime.address == session.address &&
        runtime.network == session.network;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final future = _tail.then((_) => operation());
    _tail = future.then<void>((_) {}).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      logDiagnosticError(
        'xswd.lifecycle.operation',
        error,
        stackTrace: stackTrace,
      );
      if (ref.mounted) {
        state = state.copyWith(phase: XswdLifecyclePhase.failed, error: error);
      }
    });
    return future;
  }

  Future<void> _reconcile(_XswdLifecycleTarget target, int revision) async {
    if (revision != _revision || !ref.mounted) {
      return;
    }

    final sessionChanged = !identical(_activeSession, target.session);
    final repositoryChanged = !identical(_activeRepository, target.repository);
    if (_activeRepository != null && (repositoryChanged || sessionChanged)) {
      final stopped = await _stop(
        repository: _activeRepository,
        revision: revision,
        desiredEnabled: target.desiredEnabled,
      );
      if (!stopped || revision != _revision || !ref.mounted) {
        return;
      }
    }

    if (!target.desiredEnabled || !target.canRun || target.repository == null) {
      await _stop(
        repository: target.repository ?? _activeRepository,
        revision: revision,
        desiredEnabled: target.desiredEnabled,
      );
      return;
    }

    if (!_supportsLocalServer) {
      _activeRepository = target.repository;
      _activeSession = target.session;
      state = XswdLifecycleState(
        phase: XswdLifecyclePhase.running,
        desiredEnabled: true,
      );
      return;
    }

    state = const XswdLifecycleState(
      phase: XswdLifecyclePhase.starting,
      desiredEnabled: true,
    );
    final started = await ref
        .read(xswdControllerProvider)
        .startXSWD(target.repository!);
    if (started) {
      _activeRepository = target.repository;
      _activeSession = target.session;
    }

    if (revision != _revision || !ref.mounted) {
      return;
    }

    if (!started) {
      state = const XswdLifecycleState(
        phase: XswdLifecyclePhase.failed,
        desiredEnabled: true,
      );
      return;
    }

    await _syncNotifications(active: true);
    state = const XswdLifecycleState(
      phase: XswdLifecyclePhase.running,
      desiredEnabled: true,
    );
  }

  Future<bool> _addRelayer(
    _XswdLifecycleTarget target,
    int revision,
    XelisXswdRelayer relayer,
  ) async {
    final repository = target.repository;
    if (repository == null || !_isCurrentTarget(target, revision)) {
      return false;
    }

    state = const XswdLifecycleState(
      phase: XswdLifecyclePhase.starting,
      desiredEnabled: true,
    );
    final added = await ref
        .read(xswdControllerProvider)
        .addXswdRelayer(repository, relayer);
    if (!added) {
      if (_isCurrentTarget(target, revision)) {
        state = const XswdLifecycleState(
          phase: XswdLifecyclePhase.failed,
          desiredEnabled: true,
        );
      }
      return false;
    }

    if (!_isCurrentTarget(target, revision)) {
      await ref.read(xswdControllerProvider).stopXSWD(repository);
      return false;
    }

    _activeRepository = repository;
    _activeSession = target.session;
    ref.invalidate(xswdApplicationsProvider);
    await _syncNotifications(active: true);
    if (!_isCurrentTarget(target, revision)) {
      await ref.read(xswdControllerProvider).stopXSWD(repository);
      return false;
    }

    state = const XswdLifecycleState(
      phase: XswdLifecyclePhase.running,
      desiredEnabled: true,
    );
    return true;
  }

  bool _isCurrentTarget(_XswdLifecycleTarget target, int revision) {
    if (revision != _revision || !ref.mounted) {
      return false;
    }
    final current = _readTarget();
    return current.desiredEnabled &&
        current.canRun &&
        identical(current.session, target.session) &&
        identical(current.repository, target.repository);
  }

  Future<bool> _stop({
    required NativeWalletRepository? repository,
    required int revision,
    required bool desiredEnabled,
  }) async {
    if (repository == null) {
      _activeRepository = null;
      _activeSession = null;
      if (revision == _revision && ref.mounted) {
        state = XswdLifecycleState(desiredEnabled: desiredEnabled);
      }
      await _syncNotifications(active: false);
      return true;
    }

    if (revision == _revision && ref.mounted) {
      state = XswdLifecycleState(
        phase: XswdLifecyclePhase.stopping,
        desiredEnabled: desiredEnabled,
      );
    }

    final stopped = await ref.read(xswdControllerProvider).stopXSWD(repository);
    if (!stopped) {
      if (revision == _revision && ref.mounted) {
        state = XswdLifecycleState(
          phase: XswdLifecyclePhase.failed,
          desiredEnabled: desiredEnabled,
        );
      }
      return false;
    }
    if (identical(_activeRepository, repository)) {
      _activeRepository = null;
      _activeSession = null;
    }
    await _syncNotifications(active: false);

    if (revision == _revision && ref.mounted) {
      state = XswdLifecycleState(desiredEnabled: desiredEnabled);
    }
    return true;
  }

  Future<void> _syncNotifications({required bool active}) async {
    await ref
        .read(xswdNotificationServiceProvider)
        .sync(
          active: active,
          title: ref.read(appLocalizationsProvider).connected_apps,
        );
  }

  bool get _supportsLocalServer => !kIsWeb && !Platform.isIOS;
}

class _XswdLifecycleTarget {
  const _XswdLifecycleTarget({
    required this.desiredEnabled,
    required this.session,
    required this.repository,
    required this.canRun,
  });

  final bool desiredEnabled;
  final WalletSession? session;
  final NativeWalletRepository? repository;
  final bool canRun;
}
