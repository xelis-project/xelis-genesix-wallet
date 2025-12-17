import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

/// Function type for showing toast notifications
typedef ShowToast = void Function({
  required String message,
  FToastStyle? style,
  Duration? duration,
});

/// Provider for managing toast notifications
/// This should be overridden with the actual FToast.show function from forui context
final toastProvider = Provider<ShowToast>((ref) {
  throw UnimplementedError('toastProvider must be overridden with FToast.show');
});

/// Extension to show toast messages easily
extension ToastRef on Ref {
  /// Show a toast message
  void showToast({
    required String message,
    FToastStyle? style,
    Duration? duration,
  }) {
    read(toastProvider)(
      message: message,
      style: style,
      duration: duration,
    );
  }
}
