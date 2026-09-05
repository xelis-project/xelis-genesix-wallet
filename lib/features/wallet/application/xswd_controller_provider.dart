import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_node_action_guard.dart';
import 'package:genesix/features/wallet/application/xswd_notification_service.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'xswd_controller_provider.g.dart';

@Riverpod(keepAlive: true)
XswdController xswdController(Ref ref) {
  return XswdController(ref);
}

class XswdController {
  XswdController(this.ref);

  final Ref ref;
  NativeWalletRepository? _callbackRepository;
  Object? _callbackSession;
  Object? _callbackLease;
  int _callbackGeneration = 0;
  final _closingApplicationOperations =
      Map<
        NativeWalletRepository,
        Map<XelisXswdSessionReference, Future<void>>
      >.identity();
  final _stoppingOperations =
      Map<NativeWalletRepository, Future<bool>>.identity();

  bool ensureNodeAvailable() {
    return WalletNodeActionGuard(ref).ensureNodeAvailable();
  }

  Future<bool> startXSWD(NativeWalletRepository repository) async {
    if (!WalletNodeActionGuard(ref).ensureNodeAvailable()) {
      return false;
    }

    if (kIsWeb || Platform.isIOS) {
      talker.info('XSWD skipped: unsupported platform');
      return false;
    }

    final loc = ref.read(appLocalizationsProvider);
    try {
      await _normalizePersistedXswdPermissions(repository);
      final callbacks = _buildXswdCallbacks(
        repository: repository,
        channelTitle: loc.xswd_channel_title,
      );
      await repository.startXSWD(callbacks: callbacks);
      ref.invalidate(xswdApplicationsProvider);
      talker.info('XSWD server started successfully');
      return true;
    } catch (error, stackTrace) {
      _emitFailure(
        title: loc.cannot_start_xswd,
        operation: 'xswd.server.start',
        applicationCode: 'xswd_server_start_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return false;
  }

  Future<bool> stopXSWD(NativeWalletRepository repository) {
    final existing = _stoppingOperations[repository];
    if (existing != null) return existing;

    final completer = Completer<bool>();
    _stoppingOperations[repository] = completer.future;
    unawaited(_completeXswdStop(repository, completer));
    return completer.future;
  }

  Future<void> closeXswdAppConnection(XelisXswdApplication appInfo) {
    final repository = ref.read(activeWalletRepositoryProvider);
    if (repository == null) {
      return Future.value();
    }
    return _closeXswdApplication(
      repository: repository,
      application: appInfo,
      malformed: false,
    );
  }

  Future<void> _closeXswdApplication({
    required NativeWalletRepository repository,
    required XelisXswdApplication application,
    required bool malformed,
  }) {
    final stopping = _stoppingOperations[repository];
    if (stopping != null) {
      return _closeXswdApplicationAfterStop(
        repository: repository,
        application: application,
        malformed: malformed,
        stopping: stopping,
      );
    }
    final operations = _closingApplicationOperations.putIfAbsent(
      repository,
      () => {},
    );
    final existing = operations[application.sessionReference];
    if (existing != null) return existing;

    final completer = Completer<void>();
    operations[application.sessionReference] = completer.future;
    unawaited(
      _completeXswdApplicationClose(
        repository: repository,
        application: application,
        malformed: malformed,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<void> _closeXswdApplicationAfterStop({
    required NativeWalletRepository repository,
    required XelisXswdApplication application,
    required bool malformed,
    required Future<bool> stopping,
  }) async {
    if (await stopping) return;
    await _closeXswdApplication(
      repository: repository,
      application: application,
      malformed: malformed,
    );
  }

  Future<void> _completeXswdApplicationClose({
    required NativeWalletRepository repository,
    required XelisXswdApplication application,
    required bool malformed,
    required Completer<void> completer,
  }) async {
    try {
      await _performXswdApplicationClose(
        repository: repository,
        application: application,
        malformed: malformed,
      );
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      final operations = _closingApplicationOperations[repository];
      if (identical(
        operations?[application.sessionReference],
        completer.future,
      )) {
        operations!.remove(application.sessionReference);
        if (operations.isEmpty) {
          _closingApplicationOperations.remove(repository);
        }
      }
    }
  }

  Future<void> _performXswdApplicationClose({
    required NativeWalletRepository repository,
    required XelisXswdApplication application,
    required bool malformed,
  }) async {
    final loc = ref.read(appLocalizationsProvider);
    final session = ref.read(activeWalletSessionProvider);
    final ownsActiveSession = identical(session?.repository, repository);
    if (malformed) {
      // Return the rejection to the native permission handler before reading
      // state. Admission callback projections become operable only after a
      // fresh authoritative state projection observes the same opaque session.
      await Future<void>.delayed(Duration.zero);
      try {
        final xswdState = await repository.getXswdState();
        XelisXswdApplication? connectedApplication;
        for (final candidate in xswdState.applications) {
          if (candidate.sessionReference == application.sessionReference) {
            connectedApplication = candidate;
            break;
          }
        }
        if (connectedApplication == null) return;
        await repository.removeXswdApp(connectedApplication);
      } catch (error, stackTrace) {
        if (!ownsActiveSession ||
            !ref.mounted ||
            !identical(ref.read(activeWalletSessionProvider), session)) {
          return;
        }
        _emitFailure(
          title: loc.cannot_close_xswd_connection,
          operation: 'xswd.session.terminate',
          applicationCode: 'xswd_session_close_failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return;
    }

    final pending = ref.read(xswdRequestProvider);
    if (ownsActiveSession &&
        pending.xswdEventSummary?.application.sessionReference ==
            application.sessionReference) {
      // Release the native permission callback before asking its transport to
      // close. Another application's active approval must remain untouched.
      ref.read(xswdRequestProvider.notifier).clearRequest();
    }
    try {
      await repository.removeXswdApp(application);
      if (!ownsActiveSession ||
          !ref.mounted ||
          !identical(ref.read(activeWalletSessionProvider), session)) {
        return;
      }
      ref.invalidate(xswdApplicationsProvider);
      _emitInfo(title: loc.app_disconnected_title(application.name));
    } catch (error, stackTrace) {
      if (!ownsActiveSession ||
          !ref.mounted ||
          !identical(ref.read(activeWalletSessionProvider), session)) {
        return;
      }
      _emitFailure(
        title: loc.cannot_close_xswd_connection,
        operation: 'xswd.app.disconnect',
        applicationCode: 'xswd_session_close_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> addXswdRelayer(
    NativeWalletRepository repository,
    XelisXswdRelayer relayerData,
  ) async {
    if (!WalletNodeActionGuard(ref).ensureNodeAvailable()) {
      return false;
    }

    final loc = ref.read(appLocalizationsProvider);
    try {
      await _normalizePersistedXswdPermissions(repository);
      final callbacks = _buildXswdCallbacks(
        repository: repository,
        channelTitle: loc.xswd_relayer_channel_title,
      );
      await repository.addXswdRelayer(
        callbacks: callbacks,
        relayerData: relayerData,
      );
      talker.info('XSWD relay connection added: ${relayerData.name}');
      return true;
    } catch (error, stackTrace) {
      _emitFailure(
        title: loc.cannot_add_xswd_relayer,
        operation: 'xswd.relayer.add',
        applicationCode: 'xswd_relayer_add_failed',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> editXswdAppPermission(
    XelisXswdApplication application,
    Map<String, XelisXswdPermissionPolicy> permissions,
  ) async {
    final repository = ref.read(activeWalletRepositoryProvider);
    if (repository == null) {
      return;
    }

    try {
      await repository.modifyXSWDAppPermissions(
        application,
        normalizeXswdPermissionPolicies(permissions),
      );
      ref.invalidate(xswdApplicationsProvider);
    } catch (error, stackTrace) {
      final loc = ref.read(appLocalizationsProvider);
      _emitFailure(
        title: loc.cannot_edit_xswd_app_permission,
        operation: 'xswd.app.permissions.update',
        applicationCode: 'xswd_permissions_update_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  XelisXswdCallbacks _buildXswdCallbacks({
    required NativeWalletRepository repository,
    required String channelTitle,
  }) {
    final session = ref.read(activeWalletSessionProvider);
    if (!identical(_callbackRepository, repository) ||
        !identical(_callbackSession, session)) {
      _callbackRepository = repository;
      _callbackSession = session;
      _callbackLease = Object();
      _callbackGeneration++;
    }
    final generation = _callbackGeneration;
    final lease = _callbackLease!;
    final loc = ref.read(appLocalizationsProvider);

    return XelisXswdCallbacks(
      onCancelRequest: (request) async {
        if (!_isXswdCallbackCurrent(repository, generation)) {
          return;
        }
        final appName = request.application.name;
        final message = '$channelTitle: ${loc.request_cancelled_from(appName)}';

        talker.info(message);
        final protectsAnotherSession = _hasForeignPendingXswdDecision(request);
        if (!protectsAnotherSession) {
          ref
              .read(xswdRequestProvider.notifier)
              .newRequest(xswdEventSummary: request, message: message);
        }

        if (!_isXswdToastSuppressed()) {
          _emitXswd(title: message, showOpen: false);
        }
        if (!protectsAnotherSession) {
          unawaited(
            ref.read(xswdNotificationServiceProvider).clearPendingApproval(),
          );
        }
      },
      onApplicationRequest: (request) {
        if (!_isXswdCallbackCurrent(repository, generation)) {
          return Future.value(XelisXswdDecision.reject);
        }
        final appName = request.application.name;
        final message =
            '$channelTitle: ${loc.connection_request_from(appName)}';
        return _askXswdUserPermission(
          request: request,
          repository: repository,
          generation: generation,
          lease: lease,
          message: message,
          notificationBody: loc.connection_request,
          showOpen: true,
        );
      },
      onPermissionRequest: (request) {
        if (!_isXswdCallbackCurrent(repository, generation)) {
          return Future.value(XelisXswdDecision.reject);
        }
        final appName = request.application.name;
        final message =
            '$channelTitle: ${loc.permission_request_from(appName)}';
        return _askXswdUserPermission(
          request: request,
          repository: repository,
          generation: generation,
          lease: lease,
          message: message,
          notificationBody: loc.permission_request,
          showOpen: true,
        );
      },
      onPrefetchPermissionsRequest: (request) {
        if (!_isXswdCallbackCurrent(repository, generation)) {
          return Future.value(XelisXswdDecision.reject);
        }
        final appName = request.application.name;
        final message =
            '$channelTitle: ${loc.prefetch_permissions_request_from(appName)}';
        return _askXswdUserPermission(
          request: request,
          repository: repository,
          generation: generation,
          lease: lease,
          message: message,
          notificationBody: loc.prefetch_permissions_request,
          showOpen: true,
        );
      },
      onApplicationDisconnect: (request) async {
        if (!_isXswdCallbackCurrent(repository, generation)) {
          return;
        }
        final appName = request.application.name;
        final message = '$channelTitle: ${loc.app_disconnected_title(appName)}';

        talker.info(message);
        final protectsAnotherSession = _hasForeignPendingXswdDecision(request);
        if (!protectsAnotherSession) {
          ref
              .read(xswdRequestProvider.notifier)
              .newRequest(xswdEventSummary: request, message: message);
        }
        ref.invalidate(xswdApplicationsProvider);

        if (!_isXswdToastSuppressed()) {
          _emitXswd(title: message, showOpen: false);
        }
        if (!protectsAnotherSession) {
          unawaited(
            ref.read(xswdNotificationServiceProvider).clearPendingApproval(),
          );
        }
      },
    );
  }

  bool _isXswdToastSuppressed() {
    return ref.read(xswdRequestProvider).suppressXswdToast;
  }

  bool _hasForeignPendingXswdDecision(XelisXswdRequest lifecycleRequest) {
    final pending = ref.read(xswdRequestProvider);
    final decision = pending.decision;
    if (decision == null || decision.isCompleted) {
      return false;
    }
    return pending.xswdEventSummary?.application.sessionReference !=
        lifecycleRequest.application.sessionReference;
  }

  Future<XelisXswdDecision> _askXswdUserPermission({
    required XelisXswdRequest request,
    required NativeWalletRepository repository,
    required int generation,
    required Object lease,
    required String message,
    required String notificationBody,
    required bool showOpen,
  }) async {
    if (_closingApplicationOperations[repository]?.containsKey(
          request.application.sessionReference,
        ) ??
        false) {
      return XelisXswdDecision.reject;
    }
    talker.info(message);
    final loc = ref.read(appLocalizationsProvider);

    if (!_isXswdCallbackCurrent(repository, generation)) {
      return XelisXswdDecision.reject;
    }

    late final Completer<XelisXswdDecision> decision;
    XswdPermissionReview? permissionReview;
    try {
      decision = ref
          .read(xswdRequestProvider.notifier)
          .newRequest(xswdEventSummary: request, message: message);
      permissionReview = ref.read(xswdRequestProvider).permissionReview;
    } catch (error, stackTrace) {
      ref.read(xswdRequestProvider.notifier).clearRequest();
      _emitFailure(
        title: loc.invalid_connection_data,
        operation: 'xswd.request.parse',
        applicationCode: 'xswd_request_invalid',
        error: error,
        stackTrace: stackTrace,
      );
      unawaited(
        _closeMalformedXswdSessionAfterRejection(
          repository: repository,
          application: request.application,
        ),
      );
      return XelisXswdDecision.reject;
    }

    if (!_isXswdToastSuppressed()) {
      _emitXswd(title: message, showOpen: showOpen);
    }

    final notificationService = ref.read(xswdNotificationServiceProvider);
    unawaited(
      notificationService.showPendingApproval(
        title: loc.connected_apps,
        appName: request.application.name,
        body: notificationBody,
        owner: lease,
      ),
    );

    try {
      final result = await decision.future;
      return _isXswdCallbackCurrent(repository, generation)
          ? normalizeXswdDecision(result, permissionReview)
          : XelisXswdDecision.reject;
    } finally {
      unawaited(notificationService.clearPendingApproval(owner: lease));
    }
  }

  Future<void> _normalizePersistedXswdPermissions(
    NativeWalletRepository repository,
  ) async {
    final xswdState = await repository.getXswdState();
    for (final application in xswdState.applications) {
      final normalized = normalizeXswdPermissionPolicies(
        application.permissions,
      );
      if (_samePermissionPolicies(application.permissions, normalized)) {
        continue;
      }
      await repository.modifyXSWDAppPermissions(application, normalized);
    }
  }

  Future<void> _closeMalformedXswdSession({
    required NativeWalletRepository repository,
    required XelisXswdApplication application,
  }) {
    return _closeXswdApplication(
      repository: repository,
      application: application,
      malformed: true,
    );
  }

  Future<void> _closeMalformedXswdSessionAfterRejection({
    required NativeWalletRepository repository,
    required XelisXswdApplication application,
  }) async {
    try {
      await _closeMalformedXswdSession(
        repository: repository,
        application: application,
      );
    } catch (error, stackTrace) {
      logDiagnosticError(
        'xswd.session.terminate',
        error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _isXswdCallbackCurrent(
    NativeWalletRepository repository,
    int generation,
  ) {
    return ref.mounted &&
        generation == _callbackGeneration &&
        identical(_callbackRepository, repository) &&
        identical(_callbackSession, ref.read(activeWalletSessionProvider)) &&
        identical(ref.read(activeWalletRepositoryProvider), repository);
  }

  void _invalidateXswdCallbacks(NativeWalletRepository repository) {
    if (!identical(_callbackRepository, repository)) {
      return;
    }
    _callbackRepository = null;
    _callbackSession = null;
    final lease = _callbackLease;
    _callbackLease = null;
    _callbackGeneration++;
    if (lease != null) {
      unawaited(
        ref
            .read(xswdNotificationServiceProvider)
            .clearPendingApproval(owner: lease),
      );
    }
  }

  Future<void> _completeXswdStop(
    NativeWalletRepository repository,
    Completer<bool> completer,
  ) async {
    try {
      _invalidateXswdCallbacks(repository);
      _resetXswdUiState();
      final closing = List<Future<void>>.of(
        _closingApplicationOperations[repository]?.values ?? const [],
      );
      if (closing.isNotEmpty) {
        await Future.wait(closing);
      }
      completer.complete(await _stopXswdInternal(repository, emitErrors: true));
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      if (identical(_stoppingOperations[repository], completer.future)) {
        _stoppingOperations.remove(repository);
      }
    }
  }

  Future<bool> _stopXswdInternal(
    NativeWalletRepository? repository, {
    bool emitErrors = false,
  }) async {
    if (repository == null) {
      ref.invalidate(xswdApplicationsProvider);
      return true;
    }

    try {
      await repository.stopXSWD();
      talker.info('XSWD server stop initiated');
      ref.invalidate(xswdApplicationsProvider);
      return true;
    } catch (error, stackTrace) {
      if (emitErrors) {
        final loc = ref.read(appLocalizationsProvider);
        _emitFailure(
          title: loc.cannot_stop_xswd,
          operation: 'xswd.server.stop',
          applicationCode: 'xswd_server_stop_failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
      return false;
    }
  }

  void _resetXswdUiState() {
    ref.read(xswdRequestProvider.notifier).clearRequest();
    ref.invalidate(xswdApplicationsProvider);
  }

  void _emitInfo({required String title}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.info(title: title));
  }

  void _emitFailure({
    required String title,
    required String operation,
    required String applicationCode,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final failure = recordAppFailure(
      error,
      stackTrace,
      operation: operation,
      applicationCode: applicationCode,
    );
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.failure(title: title, failure: failure));
  }

  void _emitXswd({
    required String title,
    String? description,
    required bool showOpen,
  }) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(
          WalletEffect.xswd(
            title: title,
            description: description,
            showOpen: showOpen,
          ),
        );
  }
}

Map<String, XelisXswdPermissionPolicy> normalizeXswdPermissionPolicies(
  Map<String, XelisXswdPermissionPolicy> permissions,
) {
  final normalized = Map<String, XelisXswdPermissionPolicy>.from(permissions);
  for (final entry in normalized.entries.toList(growable: false)) {
    final policy = tryXswdMethodPolicyForKey(entry.key);
    if (entry.value == XelisXswdPermissionPolicy.accept &&
        (policy == null || !policy.canPersist)) {
      normalized[entry.key] = XelisXswdPermissionPolicy.ask;
    }
  }
  return normalized;
}

XelisXswdDecision normalizeXswdDecision(
  XelisXswdDecision decision,
  XswdPermissionReview? review,
) {
  if (review?.canPersist == false &&
      decision == XelisXswdDecision.alwaysAccept) {
    return XelisXswdDecision.accept;
  }
  return decision;
}

bool _samePermissionPolicies(
  Map<String, XelisXswdPermissionPolicy> left,
  Map<String, XelisXswdPermissionPolicy> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
