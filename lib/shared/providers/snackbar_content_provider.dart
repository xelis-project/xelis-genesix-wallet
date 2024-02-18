import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';

part 'snackbar_content_provider.g.dart';

@riverpod
class SnackbarContent extends _$SnackbarContent {
  @override
  SnackbarEvent? build() {
    return null;
  }

  void setContent(SnackbarEvent content) {
    state = content.copyWith(uuid: const Uuid().v4());
  }
}
