import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'xswd_state_providers.g.dart';

@Riverpod(keepAlive: true)
class XswdDialogCoordinator extends _$XswdDialogCoordinator {
  int _lastClaimedSignal = 0;

  @override
  int build() {
    return 0;
  }

  void requestOpen() {
    state++;
  }

  bool claimOpenRequest(int signal) {
    if (signal <= _lastClaimedSignal) {
      return false;
    }

    _lastClaimedSignal = signal;
    return true;
  }
}

@Riverpod(keepAlive: true)
class XswdRequest extends _$XswdRequest {
  @override
  XswdRequestState build() {
    return const XswdRequestState(message: '', snackBarVisible: false);
  }

  Completer<XelisXswdDecision> newRequest({
    required XelisXswdRequest xswdEventSummary,
    required String message,
  }) {
    _completePendingDecision();

    final decisionCompleter = Completer<XelisXswdDecision>();

    if (xswdEventSummary.isPermissionRequest) {
      final jsonString = xswdEventSummary.payloadJson;
      if (jsonString == null) {
        throw Exception('Permission request JSON is null');
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final permissionRequest = PermissionRpcRequest.fromJson(data);
      final permissionReview = XswdPermissionReview.parse(permissionRequest);

      state = state.copyWith(
        xswdEventSummary: xswdEventSummary,
        message: message,
        decision: decisionCompleter,
        permissionRpcRequest: permissionRequest,
        permissionReview: permissionReview,
        prefetchPermissionsRequest: null,
      );
    } else if (xswdEventSummary.isPrefetchPermissionsRequest) {
      final jsonString = xswdEventSummary.payloadJson;
      if (jsonString == null) {
        throw Exception('Prefetch permissions request JSON is null');
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final prefetchRequest = PrefetchPermissionsRequest.fromJson(data);
      resolveXswdPrefetchPermissions(prefetchRequest);

      state = state.copyWith(
        xswdEventSummary: xswdEventSummary,
        message: message,
        decision: decisionCompleter,
        permissionRpcRequest: null,
        permissionReview: null,
        prefetchPermissionsRequest: prefetchRequest,
      );
    } else if (xswdEventSummary.isApplicationDisconnect ||
        xswdEventSummary.isCancelRequest) {
      state = state.copyWith(
        xswdEventSummary: xswdEventSummary,
        message: message,
        decision: null,
        permissionRpcRequest: null,
        permissionReview: null,
        prefetchPermissionsRequest: null,
      );
    } else {
      state = state.copyWith(
        xswdEventSummary: xswdEventSummary,
        message: message,
        decision: decisionCompleter,
        permissionRpcRequest: null,
        permissionReview: null,
        prefetchPermissionsRequest: null,
      );
    }

    return decisionCompleter;
  }

  void closeSnackBar() {
    state.snackBarTimer?.cancel();
    state = state.copyWith(snackBarVisible: false, snackBarTimer: null);
  }

  void setSuppressXswdToast(bool value) {
    if (!ref.mounted) return;
    if (state.suppressXswdToast == value) return;
    state = state.copyWith(suppressXswdToast: value);
  }

  void requestOpenDialog() {
    ref.read(xswdDialogCoordinatorProvider.notifier).requestOpen();
  }

  void clearRequest() {
    _completePendingDecision();
    state.snackBarTimer?.cancel();
    state = const XswdRequestState(message: '', snackBarVisible: false);
  }

  void _completePendingDecision() {
    final pendingDecision = state.decision;
    if (pendingDecision != null && !pendingDecision.isCompleted) {
      pendingDecision.complete(XelisXswdDecision.reject);
    }
  }
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

  final pendingDecision = ref.watch(
    xswdRequestProvider.select((state) => state.decision),
  );
  if (pendingDecision != null && !pendingDecision.isCompleted) {
    await pendingDecision.future;
  }

  try {
    return (await nativeWallet.getXswdState()).applications;
  } catch (error, stackTrace) {
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
