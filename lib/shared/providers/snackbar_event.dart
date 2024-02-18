// ignore_for_file: public_member_api_docs, invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'snackbar_event.freezed.dart';

@freezed
sealed class SnackbarEvent with _$SnackbarEvent {
  const factory SnackbarEvent.info({String? uuid, required String message}) =
      Info;

  const factory SnackbarEvent.error({String? uuid, required String message}) =
      Error;
}
