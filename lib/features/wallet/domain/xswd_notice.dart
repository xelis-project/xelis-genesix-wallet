import 'package:flutter/foundation.dart';

enum XswdNoticeKind { application, permission, prefetch }

/// An in-memory notification projection, without native capabilities or payloads.
@immutable
final class XswdNotice {
  const XswdNotice({
    required this.token,
    required this.applicationName,
    required this.kind,
    this.method,
    this.permissionCount,
  });

  final Object token;
  final String applicationName;
  final XswdNoticeKind kind;
  final String? method;
  final int? permissionCount;
}

@immutable
final class XswdOpenIntent {
  const XswdOpenIntent({required this.sequence, required this.token});

  final int sequence;
  final Object token;
}

@immutable
final class XswdDialogState {
  const XswdDialogState({this.intent, this.presentedToken});

  final XswdOpenIntent? intent;
  final Object? presentedToken;
}
