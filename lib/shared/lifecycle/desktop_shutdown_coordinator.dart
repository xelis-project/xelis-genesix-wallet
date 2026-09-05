import 'dart:async';

typedef DesktopShutdownAction = Future<void> Function();
typedef DesktopShutdownFailureRecorder = void Function(
  String phase,
  Object error,
  StackTrace stackTrace,
);

final class DesktopShutdownCoordinator {
  DesktopShutdownCoordinator({
    required this.closeSession,
    required this.stopLogging,
    required this.destroyWindow,
    required this.allowNativeClose,
    required this.requestNativeClose,
    required this.recordFailure,
    this.sessionTimeout = const Duration(seconds: 8),
    this.loggingTimeout = const Duration(seconds: 1),
    this.windowOperationTimeout = const Duration(seconds: 1),
  });

  static const sessionPhase = 'session';
  static const loggingPhase = 'logging';
  static const destroyPhase = 'destroy';
  static const allowNativeClosePhase = 'allow_native_close';
  static const nativeClosePhase = 'native_close';

  final DesktopShutdownAction closeSession;
  final DesktopShutdownAction stopLogging;
  final DesktopShutdownAction destroyWindow;
  final DesktopShutdownAction allowNativeClose;
  final DesktopShutdownAction requestNativeClose;
  final DesktopShutdownFailureRecorder recordFailure;
  final Duration sessionTimeout;
  final Duration loggingTimeout;
  final Duration windowOperationTimeout;

  Future<void>? _activeClose;

  Future<void> close() => _activeClose ??= _close();

  Future<void> _close() async {
    await _runBounded(
      phase: sessionPhase,
      action: closeSession,
      timeout: sessionTimeout,
    );
    await _runBounded(
      phase: loggingPhase,
      action: stopLogging,
      timeout: loggingTimeout,
    );
    await _terminateWindow();
  }

  Future<void> _terminateWindow() async {
    // Let Flutter and the platform tear down the native window normally.
    // Direct destruction is reserved for a failed native-close request.
    final nativeCloseAllowed = await _runBounded(
      phase: allowNativeClosePhase,
      action: allowNativeClose,
      timeout: windowOperationTimeout,
    );
    if (nativeCloseAllowed) {
      final nativeCloseRequested = await _runBounded(
        phase: nativeClosePhase,
        action: requestNativeClose,
        timeout: windowOperationTimeout,
      );
      if (nativeCloseRequested) return;
    }

    await _runBounded(
      phase: destroyPhase,
      action: destroyWindow,
      timeout: windowOperationTimeout,
    );
  }

  Future<bool> _runBounded({
    required String phase,
    required DesktopShutdownAction action,
    required Duration timeout,
  }) async {
    try {
      await action().timeout(timeout);
      return true;
    } catch (error, stackTrace) {
      _recordFailure(phase, error, stackTrace);
      return false;
    }
  }

  void _recordFailure(String phase, Object error, StackTrace stackTrace) {
    try {
      recordFailure(phase, error, stackTrace);
    } catch (_) {
      // Shutdown must continue even when support logging is unavailable.
    }
  }
}
