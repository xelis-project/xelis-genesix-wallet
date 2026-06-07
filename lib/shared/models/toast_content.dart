import 'package:freezed_annotation/freezed_annotation.dart';

part 'toast_content.freezed.dart';

@freezed
abstract class ToastAction with _$ToastAction {
  const factory ToastAction({
    required String label,
    @Default(false) bool isPrimary,
  }) = _ToastAction;
}

@freezed
sealed class ToastContent with _$ToastContent {
  const ToastContent._();

  const factory ToastContent.information({
    required String title,
    @Default(true) bool dismissible,
  }) = InformationToastContent;

  const factory ToastContent.warning({
    required String title,
    @Default(true) bool dismissible,
  }) = WarningToastContent;

  const factory ToastContent.error({
    required String title,
    required String description,
    @Default(false) bool sticky,
    @Default(true) bool dismissible,
  }) = ErrorToastContent;

  const factory ToastContent.event({
    required String title,
    required String description,
    @Default(false) bool sticky,
    @Default(true) bool dismissible,
  }) = EventToastContent;

  const factory ToastContent.xswd({
    required String title,
    String? description,
    @Default(<ToastAction>[]) List<ToastAction> actions,
    @Default(true) bool dismissible,
  }) = XswdToastContent;

  @override
  String get title => switch (this) {
    InformationToastContent(:final title) => title,
    WarningToastContent(:final title) => title,
    ErrorToastContent(:final title) => title,
    EventToastContent(:final title) => title,
    XswdToastContent(:final title) => title,
  };

  String? get description => switch (this) {
    InformationToastContent() => null,
    WarningToastContent() => null,
    ErrorToastContent(:final description) => description,
    EventToastContent(:final description) => description,
    XswdToastContent(:final description) => description,
  };

  List<ToastAction> get actions => switch (this) {
    XswdToastContent(:final actions) => actions,
    _ => const <ToastAction>[],
  };

  bool get sticky => switch (this) {
    ErrorToastContent(:final sticky) => sticky,
    EventToastContent(:final sticky) => sticky,
    XswdToastContent() => true,
    _ => false,
  };

  @override
  bool get dismissible => switch (this) {
    InformationToastContent(:final dismissible) => dismissible,
    WarningToastContent(:final dismissible) => dismissible,
    ErrorToastContent(:final dismissible) => dismissible,
    EventToastContent(:final dismissible) => dismissible,
    XswdToastContent(:final dismissible) => dismissible,
  };

  bool get isXswd => switch (this) {
    XswdToastContent() => true,
    _ => false,
  };
}
