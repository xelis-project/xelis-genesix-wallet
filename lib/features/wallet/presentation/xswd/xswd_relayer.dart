/// Shared model for relayed XSWD session payloads (QR / paste / deep-link).
///
/// Expected JSON shape:
/// {
///   "channel_id": "...",
///   "relayer": "https://relay.xelis.io",
///   "encryption_mode": "aes" | "chacha20poly1305" | ...,
///   "encryption_key": "<base64 32 bytes>" | null,
///   "app_data": { ... } | null
/// }
library xswd_relayer;

import 'dart:convert' show base64Decode;
import 'dart:typed_data' show Uint8List;

import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

class RelaySessionData {
  final String channelId;
  final String relayer;
  final String encryptionMode;
  final String? encryptionKey;
  final Map<String, dynamic>? appData;

  const RelaySessionData({
    required this.channelId,
    required this.relayer,
    required this.encryptionMode,
    this.encryptionKey,
    this.appData,
  });

  /// Parse from JSON (throws [FormatException] for wrong types).
  factory RelaySessionData.fromJson(Map<String, dynamic> json) {
    final channelId = json['channel_id'];
    final relayer = json['relayer'];
    final encryptionMode = json['encryption_mode'];
    final encryptionKey = json['encryption_key'];
    final appData = json['app_data'];

    if (channelId is! String) {
      throw const FormatException('RelaySessionData: channel_id must be a string');
    }
    if (relayer is! String) {
      throw const FormatException('RelaySessionData: relayer must be a string');
    }
    if (encryptionMode is! String) {
      throw const FormatException('RelaySessionData: encryption_mode must be a string');
    }
    if (encryptionKey != null && encryptionKey is! String) {
      throw const FormatException('RelaySessionData: encryption_key must be a string or null');
    }
    if (appData != null && appData is! Map<String, dynamic>) {
      throw const FormatException('RelaySessionData: app_data must be an object or null');
    }

    return RelaySessionData(
      channelId: channelId,
      relayer: relayer,
      encryptionMode: encryptionMode,
      encryptionKey: encryptionKey as String?,
      appData: appData as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'channel_id': channelId,
        'relayer': relayer,
        'encryption_mode': encryptionMode,
        'encryption_key': encryptionKey,
        'app_data': appData,
      };

  /// Basic structural validation: required fields + app_data present.
  ///
  /// Note: This does NOT validate base64 or key length. Keep that in the
  /// connection logic where you decode keys.
  bool get isValid =>
      channelId.trim().isNotEmpty &&
      relayer.trim().isNotEmpty &&
      encryptionMode.trim().isNotEmpty &&
      appData != null;

  /// Returns a human-readable reason if invalid; otherwise returns null.
  String? validateReason() {
    if (channelId.trim().isEmpty) return 'Missing channel_id';
    if (relayer.trim().isEmpty) return 'Missing relayer';
    if (encryptionMode.trim().isEmpty) return 'Missing encryption_mode';
    if (appData == null) return 'Missing app_data';
    return null;
  }

  /// Convenience: normalize relayer string (no trailing slash).
  /// This can help when constructing ws URLs like: `$relayer/ws/$channelId`.
  String get relayerNormalized {
    final r = relayer.trim();
    if (r.endsWith('/')) return r.substring(0, r.length - 1);
    return r;
  }

  /// Throw a friendly error if the session payload is structurally invalid.
  void throwIfInvalid() {
    final reason = validateReason();
    if (reason != null) {
      throw Exception('Invalid connection data: $reason');
    }
  }

  /// Builds the relayer WebSocket URL used by the wallet to connect.
  /// Example: https://relay.xelis.io/ws/<channelId>
  String buildRelayerWsUrl() => '${relayerNormalized}/ws/$channelId';

  /// Decode and validate the optional encryption key + mode from the session.
  ///
  /// - If encryptionKey is null/empty -> returns null (unencrypted session)
  /// - If provided -> must be base64 for 32 bytes and supported mode
  EncryptionMode? decodeEncryptionMode() {
    final keyB64 = encryptionKey;
    if (keyB64 == null || keyB64.trim().isEmpty) return null;

    late final Uint8List keyBytes;
    try {
      keyBytes = Uint8List.fromList(base64Decode(keyB64.trim()));
    } catch (_) {
      throw Exception('Invalid encryption_key: not valid base64');
    }

    if (keyBytes.length != 32) {
      throw Exception('Invalid encryption_key length: expected 32 bytes');
    }

    final mode = encryptionMode.trim();
    if (mode == 'aes') {
      return EncryptionMode.aes(key: keyBytes);
    }
    if (mode == 'chacha20poly1305') {
      return EncryptionMode.chacha20Poly1305(key: keyBytes);
    }

    throw Exception('Unsupported encryption mode: $mode');
  }

  /// Extract required app_data fields with safe errors.
  ///
  /// Returns a record for convenience (Dart 3).
  ({String id, String name, String description, String? url, List<String> permissions})
      parseAppData() {
    final app = appData;
    if (app == null) {
      throw Exception('Connection data missing app_data');
    }

    final id = app['id'];
    final name = app['name'];
    final description = app['description'];
    final url = app['url'];
    final permissionsRaw = app['permissions'];

    if (id is! String || id.trim().isEmpty) {
      throw Exception('app_data missing valid "id"');
    }
    if (name is! String || name.trim().isEmpty) {
      throw Exception('app_data missing valid "name"');
    }

    final desc = (description is String) ? description : '';
    final urlStr = (url is String && url.trim().isNotEmpty) ? url : null;

    final permissions = (permissionsRaw is List)
        ? permissionsRaw.whereType<String>().toList()
        : <String>[];

    return (
      id: id,
      name: name,
      description: desc,
      url: urlStr,
      permissions: permissions,
    );
  }

  /// Convert this session payload into ApplicationDataRelayer expected by your wallet layer.
  ///
  /// This calls:
  /// - throwIfInvalid()
  /// - decodeEncryptionMode()
  /// - parseAppData()
  ApplicationDataRelayer toApplicationDataRelayer() {
    throwIfInvalid();

    final enc = decodeEncryptionMode();
    final app = parseAppData();

    return ApplicationDataRelayer(
      id: app.id,
      name: app.name,
      description: app.description,
      url: app.url,
      permissions: app.permissions,
      relayer: buildRelayerWsUrl(),
      encryptionMode: enc,
    );
  }
}
