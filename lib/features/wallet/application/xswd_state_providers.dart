import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/features/logger/logger.dart';

part 'xswd_state_providers.g.dart';

@riverpod
class XswdDialogOpenSignal extends _$XswdDialogOpenSignal {
  @override
  int build() {
    return 0;
  }

  void increment() {
    state++;
  }
}

@Riverpod(keepAlive: true)
class XswdRequest extends _$XswdRequest {
  @override
  XswdRequestState build() {
    return const XswdRequestState(message: '', snackBarVisible: false);
  }

  Completer<UserPermissionDecision> newRequest({
    required XswdRequestSummary xswdEventSummary,
    required String message,
  }) {
    _completePendingDecision();

    final decisionCompleter = Completer<UserPermissionDecision>();

    try {
      if (xswdEventSummary.isPermissionRequest()) {
        final jsonString = xswdEventSummary.permissionJson();
        if (jsonString == null) {
          throw Exception('Permission request JSON is null');
        }

        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        state = state.copyWith(
          xswdEventSummary: xswdEventSummary,
          message: message,
          decision: decisionCompleter,
          permissionRpcRequest: PermissionRpcRequest.fromJson(data),
        );
      } else if (xswdEventSummary.isPrefetchPermissionsRequest()) {
        final jsonString = xswdEventSummary.prefetchPermissionsJson();
        if (jsonString == null) {
          throw Exception('Prefetch permissions request JSON is null');
        }

        final data = jsonDecode(jsonString) as Map<String, dynamic>;

        state = state.copyWith(
          xswdEventSummary: xswdEventSummary,
          message: message,
          decision: decisionCompleter,
          prefetchPermissionsRequest: PrefetchPermissionsRequest.fromJson(data),
        );
      } else if (xswdEventSummary.isAppDisconnect() ||
          xswdEventSummary.isCancelRequest()) {
        state = state.copyWith(
          xswdEventSummary: xswdEventSummary,
          message: message,
          decision: null,
        );
      } else {
        state = state.copyWith(
          xswdEventSummary: xswdEventSummary,
          message: message,
          decision: decisionCompleter,
        );
      }
    } catch (e) {
      // On error, terminate the XSWD session
      final appId = xswdEventSummary.applicationInfo.id;
      _terminateSession(appId, e);
      rethrow;
    }

    return decisionCompleter;
  }

  Future<void> _terminateSession(String appId, Object error) async {
    try {
      final nativeWallet = ref.read(activeWalletRepositoryProvider);

      if (nativeWallet != null) {
        await nativeWallet.removeXswdApp(appId);
      }
    } catch (terminateError) {
      talker.error(
        'Failed to terminate XSWD session for $appId after error: $error. Terminate error: $terminateError',
      );
    }
  }

  void closeSnackBar() {
    state.snackBarTimer?.cancel();
    state = state.copyWith(snackBarVisible: false, snackBarTimer: null);
  }

  void setSuppressXswdToast(bool value) {
    if (state.suppressXswdToast == value) return;
    state = state.copyWith(suppressXswdToast: value);
  }

  void requestOpenDialog() {
    ref.read(xswdDialogOpenSignalProvider.notifier).increment();
  }

  void clearRequest() {
    _completePendingDecision();
    state.snackBarTimer?.cancel();
    state = const XswdRequestState(message: '', snackBarVisible: false);
  }

  void _completePendingDecision() {
    final pendingDecision = state.decision;
    if (pendingDecision != null && !pendingDecision.isCompleted) {
      pendingDecision.complete(UserPermissionDecision.reject);
    }
  }
}

@riverpod
Future<List<AppInfo>> xswdApplications(Ref ref) async {
  final enableXswd = ref.watch(settingsProvider.select((s) => s.enableXswd));
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

  return nativeWallet.getXswdState();
}
