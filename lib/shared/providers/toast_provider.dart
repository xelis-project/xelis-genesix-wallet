import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toast_provider.g.dart';
part 'toast_provider.freezed.dart';

enum ToastType { information, warning, error, event, xswd }

@freezed
abstract class ToastAction with _$ToastAction {
  const factory ToastAction({
    required String label,
    @Default(false) bool isPrimary,
  }) = _ToastAction;
}

@freezed
abstract class ToastContent with _$ToastContent {
  const factory ToastContent({
    required ToastType type,
    required String title,
    String? description,

    @Default(<ToastAction>[]) List<ToastAction> actions,

    @Default(false) bool sticky,

    @Default(true) bool dismissible,
  }) = _ToastContent;
}

@riverpod
class Toast extends _$Toast {
  @override
  ToastContent? build() => null;

  void clear() => state = null;

  void show(
    ToastType type,
    String title,
    String? description, {
    List<ToastAction> actions = const [],
    bool sticky = false,
    bool dismissible = true,
  }) {
    state = ToastContent(
      type: type,
      title: title,
      description: description,
      actions: actions,
      sticky: sticky,
      dismissible: dismissible,
    );
  }

  void showInformation({required String title}) {
    show(ToastType.information, title, null);
  }

  void showWarning({required String title}) {
    show(ToastType.warning, title, null);
  }

  void showEvent({String? title, required String description}) {
    final loc = ref.read(appLocalizationsProvider);
    final eventDescription = title ?? loc.event;
    show(ToastType.event, eventDescription, description);
  }

  void showError({String? title, required String description}) {
    final loc = ref.read(appLocalizationsProvider);
    final errorDescription = title ?? loc.error;
    show(ToastType.error, errorDescription, description);
  }

  void showXswd({
    required String title,
    String? description,
    bool showOpen = true,
  }) {
    final loc = ref.read(appLocalizationsProvider);

    show(
      ToastType.xswd,
      title,
      description,
      sticky: true,
      dismissible: true,
      actions: showOpen
          ? [ToastAction(label: loc.open_button, isPrimary: true)]
          : const [],
    );
  }
}
