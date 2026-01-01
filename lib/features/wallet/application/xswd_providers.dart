import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'xswd_providers.g.dart';

@riverpod
class XswdRequest extends _$XswdRequest {
  @override
  XswdRequestState build() {
    return const XswdRequestState(message: '', snackBarVisible: false);
  }

  Completer<UserPermissionDecision> newRequest({
    required XswdRequestSummary xswdEventSummary,
    required String message,
  }) {
    final decisionCompleter = Completer<UserPermissionDecision>();

    if (xswdEventSummary.isPermissionRequest()) {
      final data =
          jsonDecode(
                (xswdEventSummary.eventType as XswdRequestType_Permission)
                    .field0,
              )
              as Map<String, dynamic>;

      state = state.copyWith(
        xswdEventSummary: xswdEventSummary,
        message: message,
        decision: decisionCompleter,
        permissionRpcRequest: PermissionRpcRequest.fromJson(data),
      );
    } else if (xswdEventSummary.isPrefetchPermissionsRequest()) {
      final data =
          jsonDecode(
                (xswdEventSummary.eventType
                        as XswdRequestType_PrefetchPermissions)
                    .field0,
              )
              as Map<String, dynamic>;

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

    return decisionCompleter;
  }

  void closeSnackBar() {
    state.snackBarTimer?.cancel();
    state = state.copyWith(snackBarVisible: false, snackBarTimer: null);
  }

  void setSuppressXswdToast(bool value) {
    if (state.suppressXswdToast == value) return;
    state = state.copyWith(suppressXswdToast: value);
  }

  void clearRequest() {
    // Complete any pending decision with reject
    final pendingDecision = state.decision;
    if (pendingDecision != null && !pendingDecision.isCompleted) {
      pendingDecision.complete(UserPermissionDecision.reject);
    }

    // Cancel any snackbar timer
    state.snackBarTimer?.cancel();

    // Reset state to initial
    state = const XswdRequestState(message: '', snackBarVisible: false);
  }
}

@riverpod
Future<List<AppInfo>> xswdApplications(Ref ref) async {
  final xswdRequest = ref.watch(xswdRequestProvider);
  final enableXswd = ref.watch(settingsProvider.select((s) => s.enableXswd));
  final nativeWallet = ref.watch(
    walletStateProvider.select((state) => state.nativeWalletRepository),
  );

  if (xswdRequest.decision != null) {
    await xswdRequest.decision!.future;
  }

  if (nativeWallet != null && enableXswd) {
    return nativeWallet.getXswdState();
  }
  return [];
}
