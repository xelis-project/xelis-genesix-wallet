import 'package:freezed_annotation/freezed_annotation.dart';

part 'toast_content.freezed.dart';

@freezed
sealed class ToastContent with _$ToastContent {
  const ToastContent._();

  const factory ToastContent.information({
    required String title,
    @Default(true) bool dismissible,
  }) = InformationToastContent;

  const factory ToastContent.warning({
    required String title,
    String? description,
    @Default(true) bool dismissible,
  }) = WarningToastContent;

  const factory ToastContent.error({
    required String title,
    required String description,
    String? supportReference,
    @Default(false) bool sticky,
    @Default(true) bool dismissible,
  }) = ErrorToastContent;

  const factory ToastContent.event({
    required String title,
    required String description,
    @Default(false) bool sticky,
    @Default(true) bool dismissible,
  }) = EventToastContent;

  @override
  String get title => switch (this) {
    InformationToastContent(:final title) => title,
    WarningToastContent(:final title) => title,
    ErrorToastContent(:final title) => title,
    EventToastContent(:final title) => title,
  };

  String? get description => switch (this) {
    InformationToastContent() => null,
    WarningToastContent(:final description) => description,
    ErrorToastContent(:final description) => description,
    EventToastContent(:final description) => description,
  };

  String? get supportReference => switch (this) {
    ErrorToastContent(:final supportReference) => supportReference,
    _ => null,
  };

  bool get sticky => switch (this) {
    ErrorToastContent(:final sticky) => sticky,
    EventToastContent(:final sticky) => sticky,
    _ => false,
  };

  @override
  bool get dismissible => switch (this) {
    InformationToastContent(:final dismissible) => dismissible,
    WarningToastContent(:final dismissible) => dismissible,
    ErrorToastContent(:final dismissible) => dismissible,
    EventToastContent(:final dismissible) => dismissible,
  };
}
