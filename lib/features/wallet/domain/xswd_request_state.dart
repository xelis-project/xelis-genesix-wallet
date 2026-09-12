import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'xswd_request_state.freezed.dart';

@freezed
abstract class XswdRequestState with _$XswdRequestState {
  const factory XswdRequestState({
    XelisXswdRequest? xswdEventSummary,
    Object? token,
    @Default(false) bool pending,
    XswdPermissionReview? permissionReview,
    XelisXswdPrefetchPermissionsRequest? prefetchPermissionsRequest,
    @Default({})
    Map<String, XelisXswdPermissionPolicy> prefetchCurrentPermissions,
    @Default('') String message,
    @Default(false) bool suppressXswdToast,
  }) = _XswdRequestState;
}

enum XswdChoiceOutcome { allowed, refused, unchanged, expired, cancelled }

enum XswdChoiceScope { request, connection }

/// A bounded presentation record, never evidence of RPC execution or authority
/// to replay a decision. It retains no request, parameters, or application data.
final class XswdRecentChoice {
  XswdRecentChoice({
    required this.sessionReference,
    required this.kind,
    required this.outcome,
    required this.scope,
    Iterable<String> methods = const [],
    Iterable<String> grantedMethods = const [],
  }) : methods = List.unmodifiable(methods),
       grantedMethods = List.unmodifiable(grantedMethods);

  final XelisXswdSessionReference sessionReference;
  final XswdNoticeKind kind;
  final XswdChoiceOutcome outcome;
  final XswdChoiceScope scope;
  final List<String> methods;
  final List<String> grantedMethods;

  @override
  String toString() =>
      'XswdRecentChoice(kind=$kind, outcome=$outcome, scope=$scope)';
}
