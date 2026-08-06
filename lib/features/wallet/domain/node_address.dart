// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'node_address.freezed.dart';

part 'node_address.g.dart';

/// UI-level mirror of the daemon-origin contract enforced by
/// `xelis-wallet-flutter`.
///
/// The native package remains the security boundary. This helper only gives
/// immediate form feedback before a connection attempt.
bool isValidDaemonOrigin(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || RegExp(r'\s').hasMatch(trimmed)) {
    return false;
  }

  // XELIS core accepts host[:port] and supplies ws/wss when no scheme exists.
  // The concrete normalization remains native-owned; using wss here is enough
  // to validate the same origin shape without changing the submitted value.
  final normalized = trimmed.contains('://') ? trimmed : 'wss://$trimmed';
  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return false;
  }

  final supportedScheme = switch (uri.scheme.toLowerCase()) {
    'http' || 'https' || 'ws' || 'wss' => true,
    _ => false,
  };
  return supportedScheme &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      (uri.path.isEmpty || uri.path == '/') &&
      !uri.hasQuery &&
      !uri.hasFragment;
}

@freezed
abstract class NodeAddress with _$NodeAddress {
  const factory NodeAddress({
    @JsonKey(name: 'name') @Default('') String name,
    @JsonKey(name: 'url') @Default('') String url,
  }) = _NodeAddress;

  factory NodeAddress.fromJson(Map<String, dynamic> json) =>
      _$NodeAddressFromJson(json);
}
