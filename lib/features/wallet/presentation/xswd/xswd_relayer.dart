/// Shared model for relayed XSWD session payloads (QR / paste / deep-link).
///
/// Expected JSON shape:
/// {
///   "relayer": "wss://relay.xelis.io/ws/abc123",  // full URL, ready to connect
///   "endpoint": "wss://relay.xelis.io",           // base, informational
///   "encryption_mode": { "mode": "aes", "key": "<hex 32 bytes>" },
///   "app_data": { ... }
/// }
library;

import 'dart:typed_data' show Uint8List;

import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

class RelaySessionData {
  final String relayer;
  final String? endpoint;
  final Map<String, dynamic> encryptionMode;
  final Map<String, dynamic>? appData;

  const RelaySessionData({
    required this.relayer,
    this.endpoint,
    required this.encryptionMode,
    this.appData,
  });

  // ---- Shim: destructure the nested encryption_mode object ----

  /// Mode string ("aes", "chacha20poly1305", ...) from encryption_mode.mode
  String? get _modeString {
    final m = encryptionMode['mode'];
    return (m is String) ? m : null;
  }

  /// Hex key string from encryption_mode.key (null/empty → null)
  String? get _keyString {
    final k = encryptionMode['key'];
    return (k is String && k.isNotEmpty) ? k : null;
  }

  // -------------------------------------------------------------

  factory RelaySessionData.fromJson(Map<String, dynamic> json) {
    final relayer = json['relayer'];
    final endpoint = json['endpoint'];
    final encryptionMode = json['encryption_mode'];
    final appData = json['app_data'];

    if (relayer is! String) {
      throw const FormatException('RelaySessionData: relayer must be a string');
    }
    if (endpoint != null && endpoint is! String) {
      throw const FormatException(
        'RelaySessionData: endpoint must be a string or null',
      );
    }
    if (encryptionMode is! Map<String, dynamic>) {
      throw const FormatException(
        'RelaySessionData: encryption_mode must be an object { mode, key }',
      );
    }
    if (appData != null && appData is! Map<String, dynamic>) {
      throw const FormatException(
        'RelaySessionData: app_data must be an object or null',
      );
    }

    return RelaySessionData(
      relayer: relayer,
      endpoint: endpoint as String?,
      encryptionMode: encryptionMode,
      appData: appData as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'relayer': relayer,
    if (endpoint != null) 'endpoint': endpoint,
    'encryption_mode': encryptionMode,
    'app_data': appData,
  };

  bool get isValid =>
      relayer.trim().isNotEmpty &&
      (_modeString?.trim().isNotEmpty ?? false) &&
      appData != null;

  String? validateReason() {
    if (relayer.trim().isEmpty) return 'Missing relayer';
    final mode = _modeString;
    if (mode == null || mode.trim().isEmpty) {
      return 'Missing encryption_mode.mode';
    }
    if (appData == null) return 'Missing app_data';
    return null;
  }

  String get relayerNormalized {
    final r = relayer.trim();
    if (r.endsWith('/')) return r.substring(0, r.length - 1);
    return r;
  }

  void throwIfInvalid() {
    final reason = validateReason();
    if (reason != null) {
      throw Exception('Invalid connection data: $reason');
    }
  }

  Uint8List _decodeHexKey(String hex) {
    final normalized = hex.trim().replaceAll(RegExp(r'^0x'), '');

    if (normalized.length % 2 != 0) {
      throw Exception(
        'Invalid encryption_mode.key: hex string must have even length',
      );
    }

    final bytes = <int>[];
    for (var i = 0; i < normalized.length; i += 2) {
      final byteStr = normalized.substring(i, i + 2);
      final value = int.tryParse(byteStr, radix: 16);
      if (value == null) {
        throw Exception('Invalid encryption_mode.key: not valid hex');
      }
      bytes.add(value);
    }

    return Uint8List.fromList(bytes);
  }

  String buildRelayerWsUrl() => relayerNormalized;

  /// Decode and validate the encryption key + mode.
  ///
  /// - If key is absent/empty → returns null (unencrypted session)
  /// - Otherwise → must be valid hex of 64 chars, with a supported mode
  EncryptionMode? decodeEncryptionMode() {
    final keyHex = _keyString;
    if (keyHex == null) return null;

    final keyBytes = _decodeHexKey(keyHex);

    if (keyBytes.length != 32) {
      throw Exception('Invalid encryption_mode.key length: expected 32 bytes');
    }

    final mode = _modeString?.trim();
    switch (mode) {
      case 'aes':
        return EncryptionMode.aes(key: keyBytes);
      case 'chacha20poly1305':
        return EncryptionMode.chacha20Poly1305(key: keyBytes);
      default:
        throw Exception('Unsupported encryption mode: $mode');
    }
  }

  ({
    String id,
    String name,
    String description,
    String? url,
    List<String> permissions,
  })
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
