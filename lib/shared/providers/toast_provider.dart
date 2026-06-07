import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/models/toast_content.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'toast_provider.g.dart';

@riverpod
class Toast extends _$Toast {
  @override
  ToastContent? build() => null;

  void clear() => state = null;

  void show(ToastContent toast) {
    state = toast;
  }

  void showInformation({required String title}) {
    show(ToastContent.information(title: title));
  }

  void showWarning({required String title}) {
    show(ToastContent.warning(title: title));
  }

  void showEvent({String? title, required String description}) {
    final loc = ref.read(appLocalizationsProvider);
    final eventDescription = title ?? loc.event;
    show(ToastContent.event(title: eventDescription, description: description));
  }

  void showError({String? title, required String description}) {
    final loc = ref.read(appLocalizationsProvider);
    final errorDescription = title ?? loc.error;
    show(ToastContent.error(title: errorDescription, description: description));
  }

  void showXswd({
    required String title,
    String? description,
    bool showOpen = true,
  }) {
    final loc = ref.read(appLocalizationsProvider);

    show(
      ToastContent.xswd(
        title: title,
        description: description,
        dismissible: true,
        actions: showOpen
            ? [ToastAction(label: loc.open_button, isPrimary: true)]
            : const [],
      ),
    );
  }
}
