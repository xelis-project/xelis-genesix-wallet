import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

/// Converts one caught error into a support-safe application failure and logs
/// that failure exactly once.
///
/// [operation], [applicationCode], and [applicationCategory] are fallback
/// metadata used only when [error] is not a [XelisWalletException]. Structured
/// package metadata and its original support ID are always preserved unchanged.
///
/// Native diagnostic messages are never read. [contextBuilder] is evaluated
/// only by the logger's explicit debug-diagnostic policy and must contain only
/// audited operational context (for example a path), never credentials, seed
/// words, private keys, or externally controlled payloads.
AppFailure recordAppFailure(
  Object error,
  StackTrace stackTrace, {
  required String operation,
  required String applicationCode,
  AppFailureCategory applicationCategory = AppFailureCategory.unexpected,
  String Function()? contextBuilder,
}) {
  final failure = appFailureFromError(
    error,
    operation: operation,
    applicationCode: applicationCode,
    applicationCategory: applicationCategory,
  );

  logAppFailure(
    failure,
    stackTrace: stackTrace,
    contextBuilder: contextBuilder,
  );
  return failure;
}

/// Converts one caught error without recording it.
///
/// Use this only for intentionally silent background attempts. A failure that
/// will be shown to the user must go through [recordAppFailure] so its support
/// identifier is present in the retained support log.
AppFailure appFailureFromError(
  Object error, {
  required String operation,
  required String applicationCode,
  AppFailureCategory applicationCategory = AppFailureCategory.unexpected,
}) {
  return error is XelisWalletException
      ? AppFailure.fromXelis(error)
      : AppFailure.application(
          operation: operation,
          code: applicationCode,
          exceptionType: error.runtimeType.toString(),
          category: applicationCategory,
        );
}
