import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/domain/xswd_payload.dart';
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
    ref.onDispose(_completePendingDecision);
    ref.listen(activeWalletSessionProvider, (previous, next) {
      if (!identical(previous, next)) clearRequest();
    });
    ref.listen(activeWalletRepositoryProvider, (previous, next) {
      if (!identical(previous, next)) clearRequest();
    });
    return const XswdRequestState();
  }

  Future<XelisXswdDecision>? get pendingDecision =>
      state.pending ? _request?.decision.future : null;

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
  }) {
    if (!identical(ref.read(activeWalletRepositoryProvider), repository)) {
      return Future.value(XelisXswdDecision.reject);
    }
    if (preflight != null && !xswdEventSummary.isPrefetchPermissionsRequest) {
      throw StateError('Unexpected XSWD prefetch review.');
    }
    PermissionRpcRequest? permissionRequest;
    XswdPermissionReview? permissionReview;
    PrefetchPermissionsRequest? prefetchRequest;
    if (xswdEventSummary.isPermissionRequest) {
      final data = decodeXswdPayload(xswdEventSummary.payload);
      if (data['jsonrpc'] != '2.0') {
        throw const FormatException('Invalid XSWD JSON-RPC version.');
      }
      normalizeXswdBuildTransactionFields(data);
      permissionRequest = PermissionRpcRequest.fromJson(data);
      permissionReview = XswdPermissionReview.parse(permissionRequest);
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
        method: permissionRequest?.method,
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
      permissionRpcRequest: permissionRequest,
      permissionReview: permissionReview,
      prefetchPermissionsRequest: prefetchRequest,
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
    _request!.decision.complete(decision);
    state = state.copyWith(pending: false);
    return true;
  }

  bool rejectIfCurrent(Object token) {
    if (!isCurrent(token) || !state.pending) return false;
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

  void _completePendingDecision() {
    final decision = _request?.decision;
    if (decision != null && !decision.isCompleted) {
      decision.complete(XelisXswdDecision.reject);
    }
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
  final Completer<XelisXswdDecision> decision = Completer<XelisXswdDecision>();
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

  final pending = ref.watch(
    xswdRequestProvider.select((state) => (state.token, state.pending)),
  );
  if (pending.$2) {
    await ref.read(xswdRequestProvider.notifier).pendingDecision;
    if (!ref.mounted ||
        !identical(ref.read(activeWalletRepositoryProvider), nativeWallet)) {
      return [];
    }
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
