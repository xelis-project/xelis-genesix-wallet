import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'snackbar_messenger_provider.g.dart';
part 'snackbar_messenger_provider.freezed.dart';

enum SnackBarType { info, error }

@freezed
class SnackBarState with _$SnackBarState {
  const factory SnackBarState({
    required SnackBarType type,
    required String message,
    required bool visible,
  }) = _SnackBarState;
}

@riverpod
class SnackBarMessenger extends _$SnackBarMessenger {
  Timer? _timer;

  @override
  SnackBarState build() {
    return const SnackBarState(
      message: '',
      type: SnackBarType.info,
      visible: false,
    );
  }

  void showError(String message) {
    state = state.copyWith(
      message: message,
      type: SnackBarType.error,
      visible: true,
    );
  }

  void showInfo(String message) {
    state = state.copyWith(
      message: message,
      type: SnackBarType.info,
      visible: true,
    );

    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(const Duration(seconds: 3), () {
      state = state.copyWith(visible: false);
    });
  }

  void hide() {
    state = state.copyWith(
      visible: false,
    );
  }
}
