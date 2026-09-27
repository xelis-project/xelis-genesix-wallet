import 'dart:convert';

import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const xswdDiagnosticLogKey = 'xswd-diagnostic';
const _maxMethods = 64;
const _maxMethodCharacters = 64;
const _maxRecordBytes = 8 * 1024;
final _methodName = RegExp(r'^[a-z][a-z0-9_.]*$');
int _nextCorrelation = 0;

enum XswdDiagnosticEvent {
  received,
  validation,
  decision,
  cancelled,
  disconnected,
}

/// Results of the real validation boundary, never inferred from method names
/// or an exception's text. Policy classifications below are supplementary.
enum XswdDiagnosticValidation { passed, failed }

enum XswdDiagnosticDisposition {
  completed,
  validationFailed,
  prefetchDeclined,
  sessionClosing,
  superseded,
}

/// Retains only bounded method metadata. It cannot retain a native request,
/// application name, parameters, free-form reason, URL, or session authority.
final class XswdDiagnosticRequest {
  XswdDiagnosticRequest._({
    required this.correlation,
    required this.kind,
    required List<({String name, String policy})> methods,
    required this.omitted,
    required this.malformedFields,
  }) : _methods = List.unmodifiable(methods);

  factory XswdDiagnosticRequest.inspect(XelisXswdRequest request) {
    final methods = <({String name, String policy})>[];
    var omitted = 0;
    var malformedFields = false;
    final payload = request.payload;
    if (request.isPermissionRequest || request.isPrefetchPermissionsRequest) {
      if (payload is! XelisXswdObjectValue) {
        malformedFields = true;
      } else if (request.isPermissionRequest) {
        methods.add(_inspectMethod(payload.fields['method'], prefetch: false));
        malformedFields = payload.fields['method'] is! XelisXswdStringValue;
      } else {
        final permissions = payload.fields['permissions'];
        if (permissions is! XelisXswdArrayValue) {
          malformedFields = true;
        } else {
          final count = permissions.values.length;
          omitted = count > _maxMethods ? count - _maxMethods : 0;
          for (final value in permissions.values.take(_maxMethods)) {
            methods.add(_inspectMethod(value, prefetch: true));
            malformedFields |= value is! XelisXswdStringValue;
          }
        }
      }
    }
    return XswdDiagnosticRequest._(
      correlation: ++_nextCorrelation,
      kind: request.kind,
      methods: methods,
      omitted: omitted,
      malformedFields: malformedFields,
    );
  }

  final int correlation;
  final XelisXswdRequestKind kind;
  final List<({String name, String policy})> _methods;
  final int omitted;
  final bool malformedFields;

  void record(
    XswdDiagnosticEvent event, {
    XswdDiagnosticValidation? validation,
    XelisXswdDecision? decision,
    XswdDiagnosticDisposition? disposition,
    Iterable<String>? grantedPermissions,
  }) {
    if (!diagnosticLoggingEnabled) return;
    talker.logCustom(
      TalkerLog(
        format(
          event,
          validation: validation,
          decision: decision,
          disposition: disposition,
          grantedPermissions: grantedPermissions,
        ),
        key: xswdDiagnosticLogKey,
        title: 'XSWD diagnostic',
        logLevel: LogLevel.debug,
      ),
    );
  }

  /// All fields are fixed ASCII metadata or sanitized method names. Keeping
  /// this formatter pure also allows hostile-input boundary tests.
  String format(
    XswdDiagnosticEvent event, {
    XswdDiagnosticValidation? validation,
    XelisXswdDecision? decision,
    XswdDiagnosticDisposition? disposition,
    Iterable<String>? grantedPermissions,
  }) {
    final selected = grantedPermissions?.take(_maxMethods).toSet();
    final renderedMethods = <Map<String, Object>>[];
    final record = <String, Object>{
      'request': correlation,
      'kind': kind.name,
      'event': event.name,
      if (validation != null) 'validation': validation.name,
      if (decision != null) 'decision': decision.name,
      if (disposition != null) 'disposition': disposition.name,
      'malformedFields': malformedFields,
      'methods': renderedMethods,
      'omitted': omitted,
    };
    for (var index = 0; index < _methods.length; index++) {
      final method = _methods[index];
      renderedMethods.add({
        'name': method.name,
        'policy': method.policy,
        if (selected != null) 'selected': selected.contains(method.name),
      });
      // Include the omitted count in the budget, so truncation stays valid JSON.
      record['omitted'] = omitted + _methods.length - index - 1;
      if (utf8.encode(jsonEncode(record)).length > _maxRecordBytes) {
        renderedMethods.removeLast();
        record['omitted'] = omitted + _methods.length - index;
        break;
      }
    }
    return jsonEncode(record);
  }
}

({String name, String policy}) _inspectMethod(
  XelisXswdValue? value, {
  required bool prefetch,
}) {
  if (value is! XelisXswdStringValue ||
      value.value.length > _maxMethodCharacters ||
      !_methodName.hasMatch(value.value)) {
    return (name: '[invalid-method]', policy: 'invalidName');
  }
  final name = value.value;
  // Exact policy lookup: never trim, strip a prefix, or normalize spelling.
  final policy = tryXswdMethodPolicyForKey(name);
  return (
    name: name,
    policy: policy == null
        ? 'unknown'
        : !policy.isSupported
        ? 'unsupported'
        : prefetch && !policy.canPrefetch
        ? 'notPrefetchable'
        : 'supported',
  );
}
