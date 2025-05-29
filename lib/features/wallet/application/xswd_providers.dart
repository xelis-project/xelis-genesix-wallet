import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'xswd_providers.g.dart';

@riverpod
class XswdRequest extends _$XswdRequest {
  @override
  XswdRequestState build() {
    ref.watch(authenticationProvider);
    return const XswdRequestState(message: '', snackBarVisible: false);
  }

  Completer<UserPermissionDecision> newRequest({
    required XswdRequestSummary xswdEventSummary,
    required String message,
    int snackBarDuration = 10,
  }) {
    final decisionCompleter = Completer<UserPermissionDecision>();
    final snackBarTimer = Timer(
      Duration(
        seconds:
            xswdEventSummary.isCancelRequest() ||
                xswdEventSummary.isAppDisconnect()
            ? 5
            : snackBarDuration,
      ),
      () {
        decisionCompleter.complete(UserPermissionDecision.reject);
        state = state.copyWith(snackBarVisible: false);
      },
    );

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
        snackBarTimer: snackBarTimer,
        decision: decisionCompleter,
        permissionRpcRequest: PermissionRpcRequest.fromJson(data),
        snackBarVisible: true,
      );
    } else if (xswdEventSummary.isAppDisconnect() ||
        xswdEventSummary.isCancelRequest()) {
      state = state.copyWith(
        xswdEventSummary: xswdEventSummary,
        message: message,
        snackBarTimer: snackBarTimer,
        snackBarVisible: true,
      );
    } else {
      state = state.copyWith(
        xswdEventSummary: xswdEventSummary,
        message: message,
        snackBarTimer: snackBarTimer,
        decision: decisionCompleter,
        snackBarVisible: true,
      );
    }

    return decisionCompleter;
  }

  void closeSnackBar() {
    state = state.copyWith(snackBarVisible: false);
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
