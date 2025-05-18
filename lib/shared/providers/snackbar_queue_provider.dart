import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'snackbar_queue_provider.g.dart';

part 'snackbar_queue_provider.freezed.dart';

enum SnackBarType { info, error }

@freezed
abstract class SnackBarState with _$SnackBarState {
  const factory SnackBarState({
    required SnackBarType type,
    required String message,
    required String id,
    Duration? duration,
  }) = _SnackBarState;
}

@riverpod
class SnackBarQueue extends _$SnackBarQueue {
  final List<SnackBarState> _queue = [];

  @override
  List<SnackBarState> build() => [];

  void show(SnackBarType type, String message, {Duration? duration}) {
    final snack = SnackBarState(
      id: Uuid().v4(),
      type: type,
      message: message,
      duration: duration, // null = infinite
    );

    _queue.add(snack);
    state = [..._queue];

    if (duration != null) {
      Future.delayed(duration, () {
        remove(snack.id);
      });
    }
  }

  void remove(String id) {
    _queue.removeWhere((s) => s.id == id);
    state = [..._queue];
  }

  void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(SnackBarType.info, message, duration: duration);
  }

  void showError(String message) {
    show(SnackBarType.error, message, duration: const Duration(seconds: 4));
  }
}
