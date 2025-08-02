import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toast_provider.g.dart';

part 'toast_provider.freezed.dart';

enum ToastType { information, warning, error, event }

@freezed
abstract class ToastContent with _$ToastContent {
  const factory ToastContent({
    required ToastType type,
    required String title,
    String? description,
  }) = _ToastContent;
}

@riverpod
class Toast extends _$Toast {
  @override
  ToastContent? build() => null;

  void show(ToastType type, String title, String? description) {
    state = ToastContent(type: type, title: title, description: description);
  }

  void showInformation({required String title}) {
    show(ToastType.information, title, null);
  }

  void showWarning({required String title}) {
    show(ToastType.warning, title, null);
  }

  void showEvent({String? title, required String description}) {
    // TODO
    final loc = ref.read(appLocalizationsProvider);
    final eventDescription = title ?? 'Event';
    show(ToastType.event, eventDescription, description);
  }

  void showError({String? title, required String description}) {
    final loc = ref.read(appLocalizationsProvider);
    final errorDescription = title ?? loc.error;
    show(ToastType.error, errorDescription, description);
  }
}
