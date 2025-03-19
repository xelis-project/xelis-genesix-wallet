import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'xswd_provider.g.dart';

part 'xswd_provider.freezed.dart';

@freezed
abstract class XswdRequestState with _$XswdRequestState {
  const factory XswdRequestState({
    XswdRequestSummary? xswdEventSummary,
    Timer? snackBarTimer,
    Completer<UserPermissionDecision>? decision,
    required String message,
    required bool snackBarVisible,
  }) = _XswdRequestState;
}

@riverpod
class Xswd extends _$Xswd {
  @override
  XswdRequestState build() {
    final enableXswd = ref.watch(settingsProvider.select((s) => s.enableXswd));
    if (enableXswd) {
      ref.read(walletStateProvider.notifier).startXSWD();
    } else {
      ref.read(walletStateProvider.notifier).stopXSWD();
    }
    return const XswdRequestState(message: '', snackBarVisible: false);
  }

  Completer<UserPermissionDecision> newRequest({
    required XswdRequestSummary xswdEventSummary,
    required String message,
    int snackBarDuration = 10,
  }) {
    final decisionCompleter = Completer<UserPermissionDecision>();
    final snackBarTimer = Timer(Duration(seconds: snackBarDuration), () {
      decisionCompleter.complete(UserPermissionDecision.deny);
      state = state.copyWith(snackBarVisible: false);
    });

    state = state.copyWith(
      xswdEventSummary: xswdEventSummary,
      message: message,
      snackBarTimer: snackBarTimer,
      decision: decisionCompleter,
      snackBarVisible: true,
    );

    return decisionCompleter;
  }

  void closeSnackBar() {
    state = state.copyWith(snackBarVisible: false);
  }
}
