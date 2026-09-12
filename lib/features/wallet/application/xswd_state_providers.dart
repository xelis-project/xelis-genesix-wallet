import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'xswd_state_providers.g.dart';

@Riverpod(keepAlive: true)
class XswdDialogCoordinator extends _$XswdDialogCoordinator {
  int _sequence = 0;
  int _lastClaimedSignal = 0;

  @override
  XswdDialogState build() => const XswdDialogState();

  void requestOpen(Object token) {
    if (!ref.mounted) return;
    state = XswdDialogState(
      intent: XswdOpenIntent(sequence: ++_sequence, token: token),
      presentedToken: state.presentedToken,
    );
  }

  bool claimOpenRequest(XswdOpenIntent intent) {
    if (!ref.mounted) return false;
    if (intent.sequence <= _lastClaimedSignal ||
        !identical(state.intent, intent) ||
        !ref.read(xswdRequestProvider.notifier).isCurrent(intent.token)) {
      return false;
    }
    _lastClaimedSignal = intent.sequence;
    return true;
  }

  void markPresented(Object token) {
    if (!ref.mounted) return;
    if (!ref.read(xswdRequestProvider.notifier).isCurrent(token)) return;
    state = XswdDialogState(intent: state.intent, presentedToken: token);
  }

  void clearPresented(Object token) {
    if (!ref.mounted) return;
    if (!identical(state.presentedToken, token)) return;
    state = XswdDialogState(intent: state.intent);
  }
}

@Riverpod(keepAlive: true)
class XswdRequest extends _$XswdRequest {
  _OwnedXswdRequest? _request;

  @override
  XswdRequestState build() {
    ref.onDispose(() => _completePendingDecision(recordChoice: false));
    ref.listen(activeWalletSessionProvider, (previous, next) {
      if (!identical(previous, next)) clearRequest();
    });
    ref.listen(activeWalletRepositoryProvider, (previous, next) {
      if (!identical(previous, next)) clearRequest();
    });
    return const XswdRequestState();
  }

  Future<XelisXswdDecision>? get pendingDecision => state.pending
      ? _request?.decision.future.then((result) => result.decision)
      : null;

  XswdNotice? get currentNotice {
    final request = state.xswdEventSummary;
    final token = state.token;
    if (request == null ||
        token == null ||
        !state.pending ||
        !isCurrent(token)) {
      return null;
    }
    return _request?.notice;
  }

  Future<XelisXswdDecision> newRequest({
    required XelisXswdRequest xswdEventSummary,
    required String message,
    required NativeWalletRepository repository,
    XswdPrefetchPreflight? preflight,
    Map<String, XelisXswdPermissionPolicy> currentPermissions = const {},
  }) => _newRequest(
    xswdEventSummary: xswdEventSummary,
    message: message,
    repository: repository,
    preflight: preflight,
    currentPermissions: currentPermissions,
  ).then((result) => result.decision);

  Future<XelisXswdPrefetchDecision> newPrefetchRequest({
    required XswdPrefetchPreflight preflight,
    required String message,
    required NativeWalletRepository repository,
    required Map<String, XelisXswdPermissionPolicy> currentPermissions,
  }) =>
      _newRequest(
        xswdEventSummary: preflight.source,
        message: message,
        repository: repository,
        preflight: preflight,
        currentPermissions: currentPermissions,
      ).then(
        (result) => result.grantedMethods.isEmpty
            ? const XelisXswdPrefetchDecision.noChange()
            : XelisXswdPrefetchDecision.grant(result.grantedMethods),
      );

  Future<_XswdApprovalDecision> _newRequest({
    required XelisXswdRequest xswdEventSummary,
    required String message,
    required NativeWalletRepository repository,
    XswdPrefetchPreflight? preflight,
    required Map<String, XelisXswdPermissionPolicy> currentPermissions,
  }) {
    if (!identical(ref.read(activeWalletRepositoryProvider), repository)) {
      return Future.value(
        const _XswdApprovalDecision(XelisXswdDecision.reject),
      );
    }
    if (preflight != null && !xswdEventSummary.isPrefetchPermissionsRequest) {
      throw StateError('Unexpected XSWD prefetch review.');
    }
    XswdPermissionReview? permissionReview;
    XelisXswdPrefetchPermissionsRequest? prefetchRequest;
    if (xswdEventSummary.isPermissionRequest) {
      permissionReview = XswdPermissionReview.parse(
        xswdEventSummary.permissionRequest!,
      );
    } else if (xswdEventSummary.isPrefetchPermissionsRequest) {
      final checked =
          preflight ?? XswdPrefetchPreflight.parse(xswdEventSummary);
      if (!identical(checked.source, xswdEventSummary) ||
          checked.disposition != XswdPrefetchDisposition.grantable) {
        throw StateError('Expected a grantable review for this XSWD request.');
      }
      prefetchRequest = checked.request;
    } else if (!xswdEventSummary.isApplicationRequest) {
      throw const FormatException('Expected an XSWD approval request.');
    }

    // Validate before replacing an unrelated, already reviewable request.
    _completePendingDecision();
    final request = _OwnedXswdRequest(
      notice: XswdNotice(
        token: Object(),
        applicationName: xswdEventSummary.application.name,
        kind: xswdEventSummary.isPermissionRequest
            ? XswdNoticeKind.permission
            : xswdEventSummary.isPrefetchPermissionsRequest
            ? XswdNoticeKind.prefetch
            : XswdNoticeKind.application,
        method: permissionReview?.method,
        permissionCount: prefetchRequest?.permissions.length,
      ),
      repository: repository,
      walletSession: ref.read(activeWalletSessionProvider),
      sessionReference: xswdEventSummary.application.sessionReference,
    );
    _request = request;
    state = XswdRequestState(
      token: request.token,
      pending: true,
      xswdEventSummary: xswdEventSummary,
      message: message,
      permissionReview: permissionReview,
      prefetchPermissionsRequest: prefetchRequest,
      prefetchCurrentPermissions: Map.unmodifiable(currentPermissions),
      suppressXswdToast: state.suppressXswdToast,
    );
    return request.decision.future;
  }

  bool isCurrent(Object token) {
    if (!ref.mounted) return false;
    final request = _request;
    return request != null &&
        identical(request.token, token) &&
        identical(state.token, token) &&
        identical(
          ref.read(activeWalletRepositoryProvider),
          request.repository,
        ) &&
        identical(
          ref.read(activeWalletSessionProvider),
          request.walletSession,
        ) &&
        state.xswdEventSummary?.application.sessionReference ==
            request.sessionReference;
  }

  bool requestOpenIfCurrent(Object token) {
    if (!isCurrent(token) || !state.pending) return false;
    ref.read(xswdDialogCoordinatorProvider.notifier).requestOpen(token);
    return true;
  }

  bool resolveIfCurrent(Object token, XelisXswdDecision decision) {
    if (!isCurrent(token) || !state.pending) return false;
    // A batch must carry its explicit selection. The binary legacy command
    // can only leave permissions unchanged, never imply a full grant.
    if (state.prefetchPermissionsRequest != null) {
      return resolvePrefetchIfCurrent(token, const []);
    }
    if (state.permissionReview?.canPersist == false &&
        decision == XelisXswdDecision.alwaysAccept) {
      decision = XelisXswdDecision.accept;
    }
    _request!.decision.complete(_XswdApprovalDecision(decision));
    state = state.copyWith(pending: false);
    _recordChoice(
      decision == XelisXswdDecision.accept ||
              decision == XelisXswdDecision.alwaysAccept
          ? XswdChoiceOutcome.allowed
          : XswdChoiceOutcome.refused,
      decision: decision,
    );
    return true;
  }

  bool resolvePrefetchIfCurrent(Object token, Iterable<String> permissions) {
    if (!isCurrent(token) || !state.pending) return false;
    final prefetch = state.prefetchPermissionsRequest;
    if (prefetch == null) return false;
    final granted = <String>[];
    final unique = <String>{};
    for (final permission in permissions) {
      if (granted.length >= xswdMethodCount ||
          !unique.add(permission) ||
          !prefetch.permissions.contains(permission) ||
          tryXswdMethodPolicyForKey(permission)?.canPrefetch != true) {
        return false;
      }
      granted.add(permission);
    }
    final immutable = List<String>.unmodifiable(granted);
    final decision = immutable.isEmpty
        ? XelisXswdDecision.reject
        : XelisXswdDecision.accept;
    _request!.decision.complete(_XswdApprovalDecision(decision, immutable));
    state = state.copyWith(pending: false);
    _recordChoice(
      immutable.isEmpty
          ? XswdChoiceOutcome.unchanged
          : XswdChoiceOutcome.allowed,
      decision: decision,
      grantedMethods: immutable,
    );
    return true;
  }

  bool rejectIfCurrent(Object token, {bool expired = false}) {
    if (!isCurrent(token) || !state.pending) return false;
    _completePendingDecision(
      outcome: expired ? XswdChoiceOutcome.expired : XswdChoiceOutcome.refused,
    );
    return clearIfCurrent(token);
  }

  bool clearIfCurrent(Object token) {
    if (!isCurrent(token)) return false;
    clearRequest();
    return true;
  }

  void setSuppressXswdToast(bool value, {required Object token}) {
    if (!isCurrent(token) || state.suppressXswdToast == value) return;
    state = state.copyWith(suppressXswdToast: value);
  }

  /// Privileged wallet/session teardown. UI actions must use tokenized commands.
  void clearRequest() {
    _completePendingDecision();
    final token = state.token;
    _request = null;
    state = const XswdRequestState();
    if (token != null) {
      ref.read(xswdDialogCoordinatorProvider.notifier).clearPresented(token);
    }
  }

  void _completePendingDecision({
    bool recordChoice = true,
    XswdChoiceOutcome outcome = XswdChoiceOutcome.cancelled,
  }) {
    final decision = _request?.decision;
    if (decision != null && !decision.isCompleted) {
      // Dependency reads can synchronously re-enter teardown on wallet change.
      decision.complete(const _XswdApprovalDecision(XelisXswdDecision.reject));
      if (recordChoice) _recordChoice(outcome);
    }
  }

  void _recordChoice(
    XswdChoiceOutcome outcome, {
    XelisXswdDecision decision = XelisXswdDecision.reject,
    List<String> grantedMethods = const [],
  }) {
    final request = _request;
    if (request == null || !isCurrent(request.token)) return;
    final method = state.permissionReview?.method;
    final prefetch = state.prefetchPermissionsRequest;
    final forConnection =
        request.notice.kind == XswdNoticeKind.application ||
        prefetch != null ||
        decision == XelisXswdDecision.alwaysAccept ||
        decision == XelisXswdDecision.alwaysReject;
    ref
        .read(xswdRecentChoicesProvider.notifier)
        .record(
          XswdRecentChoice(
            sessionReference: request.sessionReference,
            kind: request.notice.kind,
            outcome: prefetch != null && outcome == XswdChoiceOutcome.refused
                ? XswdChoiceOutcome.unchanged
                : outcome,
            scope: forConnection
                ? XswdChoiceScope.connection
                : XswdChoiceScope.request,
            methods: method != null
                ? [method]
                : prefetch?.permissions ?? const [],
            grantedMethods: grantedMethods,
          ),
        );
  }
}

final class _OwnedXswdRequest {
  _OwnedXswdRequest({
    required this.notice,
    required this.repository,
    required this.walletSession,
    required this.sessionReference,
  });

  final XswdNotice notice;
  Object get token => notice.token;
  final NativeWalletRepository repository;
  final Object? walletSession;
  final XelisXswdSessionReference sessionReference;
  final Completer<_XswdApprovalDecision> decision =
      Completer<_XswdApprovalDecision>();
}

/// Completed together so no continuation reads a successor's mutable state.
final class _XswdApprovalDecision {
  const _XswdApprovalDecision(this.decision, [this.grantedMethods = const []]);
  final XelisXswdDecision decision;
  final List<String> grantedMethods;
}

@Riverpod(keepAlive: true)
class XswdRecentChoices extends _$XswdRecentChoices {
  static const capacity = 20;

  @override
  List<XswdRecentChoice> build() {
    ref.watch(activeWalletSessionProvider);
    ref.watch(activeWalletRepositoryProvider);
    return const [];
  }

  void record(XswdRecentChoice choice) {
    state = List.unmodifiable([choice, ...state.take(capacity - 1)]);
  }

  void removeSession(XelisXswdSessionReference session) {
    state = List.unmodifiable(
      state.where((choice) => choice.sessionReference != session),
    );
  }

  void clear() => state = const [];
}

@Riverpod(keepAlive: true)
class XswdApplicationObservations extends _$XswdApplicationObservations {
  @override
  Map<XelisXswdSessionReference, XelisXswdApplicationStateObservation> build() {
    ref.watch(activeWalletSessionProvider);
    ref.watch(activeWalletRepositoryProvider);
    return const {};
  }

  bool record(XelisXswdApplicationStateObservation observation) {
    final session = observation.application.sessionReference;
    final previous = state[session];
    if (previous == null && observation is XelisXswdApplicationStateStale) {
      return false;
    }
    if (previous != null && observation.sequence <= previous.sequence) {
      return false;
    }
    state = Map.unmodifiable({...state, session: observation});
    return true;
  }

  void removeSession(XelisXswdSessionReference session) {
    state = Map.unmodifiable({...state}..remove(session));
  }

  void clear() => state = const {};
}

@riverpod
bool effectiveXswdEnabled(Ref ref) {
  final settings = ref.watch(
    settingsProvider.select(
      (settings) => (
        enableXswd: settings.enableXswd,
        walletOfflineMode: settings.walletOfflineMode,
      ),
    ),
  );

  return settings.enableXswd && !settings.walletOfflineMode;
}

@riverpod
Future<List<XelisXswdApplication>> xswdApplications(Ref ref) async {
  final enableXswd = ref.watch(effectiveXswdEnabledProvider);
  final nativeWallet = ref.watch(activeWalletRepositoryProvider);
  if (nativeWallet == null || !enableXswd) {
    return [];
  }

  try {
    return (await nativeWallet.getXswdState()).applications;
  } catch (error, stackTrace) {
    if (!ref.mounted ||
        !identical(ref.read(activeWalletRepositoryProvider), nativeWallet)) {
      return [];
    }
    final failure = recordAppFailure(
      error,
      stackTrace,
      operation: 'xswd.state.read',
      applicationCode: 'xswd_state_read_failed',
    );
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(
          WalletEffect.failure(
            title: ref
                .read(appLocalizationsProvider)
                .error_loading_applications,
            failure: failure,
          ),
        );
    return [];
  }
}
