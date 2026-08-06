import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart' as xelis;

const String supportLogKey = 'support';

/// Rich diagnostics are deliberately limited to debug builds.
///
/// They are enabled by default while developing and can be disabled with
/// `--dart-define=GENESIX_DIAGNOSTICS=false`. Release/profile builds always use
/// the safe support policy, even if the define is supplied.
const bool diagnosticLoggingEnabled =
    kDebugMode &&
    bool.fromEnvironment('GENESIX_DIAGNOSTICS', defaultValue: true);

const bool _rustTraceEnabled =
    diagnosticLoggingEnabled &&
    bool.fromEnvironment('GENESIX_RUST_TRACE', defaultValue: false);

final talker = TalkerFlutter.init(
  settings: TalkerSettings(
    useHistory: true,
    useConsoleLogs: kDebugMode,
    maxHistoryItems: diagnosticLoggingEnabled ? 1000 : 200,
  ),
  filter: diagnosticLoggingEnabled
      ? TalkerFilter()
      : TalkerFilter(enabledKeys: const [supportLogKey]),
);

enum AppSupportEvent {
  rustLoggerInitializationFailed,
  rustLogStreamFailed,
  desktopShutdownFailed,
  xswdQrPayloadRejected,
  xswdPastedPayloadRejected,
}

extension on AppSupportEvent {
  ({String source, String operation, String code, String message})
  get description => switch (this) {
    AppSupportEvent.rustLoggerInitializationFailed => (
      source: 'xelis_wallet_flutter',
      operation: 'logging.initialize',
      code: 'native_logger_init_failed',
      message: 'Native logging could not be initialized',
    ),
    AppSupportEvent.rustLogStreamFailed => (
      source: 'xelis_wallet_flutter',
      operation: 'logging.stream',
      code: 'native_log_stream_failed',
      message: 'The native log stream reported an error',
    ),
    AppSupportEvent.desktopShutdownFailed => (
      source: 'genesix',
      operation: 'application.shutdown',
      code: 'desktop_shutdown_failed',
      message: 'Desktop shutdown cleanup reported an error',
    ),
    AppSupportEvent.xswdQrPayloadRejected => (
      source: 'genesix',
      operation: 'xswd.qr.decode',
      code: 'xswd_qr_payload_rejected',
      message: 'An XSWD QR payload was rejected',
    ),
    AppSupportEvent.xswdPastedPayloadRejected => (
      source: 'genesix',
      operation: 'xswd.paste.decode',
      code: 'xswd_pasted_payload_rejected',
      message: 'A pasted XSWD payload was rejected',
    ),
  };
}

/// Records a fixed, production-safe event that can be used by support.
///
/// [diagnosticContext] and [stackTrace] are included only in an enabled debug
/// diagnostic build. Callers must still never pass seeds, private keys,
/// passwords, tokens, raw XSWD payloads, or complete external JSON.
void logSupportEvent(
  AppSupportEvent event, {
  String? diagnosticContext,
  StackTrace? stackTrace,
}) {
  final description = event.description;
  final safeMessage =
      'source=${description.source} '
      'operation=${description.operation} '
      'code=${description.code}: ${description.message}';
  final message = diagnosticLoggingEnabled && diagnosticContext != null
      ? '$safeMessage\n$diagnosticContext'
      : safeMessage;

  talker.logCustom(
    TalkerLog(
      message,
      key: supportLogKey,
      title: 'Support',
      logLevel: LogLevel.error,
      stackTrace: diagnosticLoggingEnabled ? stackTrace : null,
    ),
  );
}

/// Records the support-safe fields of a structured application failure.
///
/// [contextBuilder] is evaluated only in an enabled debug diagnostic build.
/// Callers may provide audited operational context such as a sanitized path,
/// amount, hash, or endpoint, but must never include secrets or raw payloads.
/// Native diagnostic messages are deliberately absent from [AppFailure] and
/// cannot be recorded through this function.
void logAppFailure(
  AppFailure failure, {
  StackTrace? stackTrace,
  String Function()? contextBuilder,
}) {
  final nativeKindField = failure.nativeKind == null
      ? ''
      : ' nativeKind=${failure.nativeKind}';
  final nativeCodeField = failure.nativeCode == null
      ? ''
      : ' nativeCode=${failure.nativeCode}';
  final originContractVersionField = failure.originContractVersion == null
      ? ''
      : ' originContractVersion=${failure.originContractVersion}';
  final safeMessage =
      'contractVersion=${failure.contractVersion} '
      'exceptionType=${failure.exceptionType} '
      'source=${failure.source} '
      'operation=${failure.operation} '
      'code=${failure.code} '
      'supportId=${failure.supportId}'
      '$originContractVersionField'
      '$nativeKindField'
      '$nativeCodeField';
  final context = diagnosticLoggingEnabled ? contextBuilder?.call() : null;
  final message = context == null ? safeMessage : '$safeMessage\n$context';

  talker.logCustom(
    TalkerLog(
      message,
      key: supportLogKey,
      title: 'Wallet failure',
      logLevel: LogLevel.error,
      stackTrace: diagnosticLoggingEnabled ? stackTrace : null,
    ),
  );
}

/// Records development-only operational context.
///
/// Paths, amounts, hashes, and sanitized endpoints may be useful here. Secrets
/// and complete externally controlled payloads remain forbidden in every mode.
void logDiagnostic(String Function() messageBuilder) {
  if (!diagnosticLoggingEnabled) return;
  talker.debug(messageBuilder());
}

/// Records an error type and optional audited context without interpolating the
/// error object itself. Native/RPC exception strings can contain full payloads.
void logDiagnosticError(
  String operation,
  Object error, {
  StackTrace? stackTrace,
  String Function()? contextBuilder,
}) {
  if (!diagnosticLoggingEnabled) return;

  final context = contextBuilder?.call();
  final message =
      'operation=$operation errorType=${error.runtimeType}'
      '${context == null ? '' : ' $context'}';
  talker.logCustom(
    TalkerLog(
      message,
      key: 'diagnostic-error',
      title: 'Diagnostic error',
      logLevel: LogLevel.error,
      stackTrace: stackTrace,
    ),
  );
}

/// Removes credentials, path, query, and fragment from a network endpoint.
String sanitizeEndpointForDiagnostics(String endpoint) {
  final uri = Uri.tryParse(endpoint);
  if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
    return 'unparseable-endpoint';
  }

  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}

const Set<String> _sensitiveProviders = {
  'walletRuntimeProvider',
  'historyProvider',
  'lastTransactionsProvider',
  'historyPagingStateProvider',
  'walletSessionProvider',
  'xswdRequestProvider',
};

const Set<String> _noisyProviders = {'xelisPriceProvider'};

TalkerRiverpodLoggerSettings _riverpodLoggerSettings() {
  return TalkerRiverpodLoggerSettings(
    enabled: diagnosticLoggingEnabled,
    printProviderDisposed: diagnosticLoggingEnabled,
    printStateFullData: false,
    printFailFullData: false,
    providerFilter: (provider) =>
        !_sensitiveProviders.contains(provider.name) &&
        !_noisyProviders.contains(provider.name),
  );
}

List<ProviderObserver> riverpodObserversMinimal() {
  return [
    TalkerRiverpodObserver(talker: talker, settings: _riverpodLoggerSettings()),
  ];
}

LogLevel _mapLogLevel(xelis.XelisLogLevel level) => switch (level) {
  xelis.XelisLogLevel.error => LogLevel.error,
  xelis.XelisLogLevel.warn => LogLevel.warning,
  xelis.XelisLogLevel.info => LogLevel.info,
  xelis.XelisLogLevel.debug => LogLevel.debug,
  xelis.XelisLogLevel.trace => LogLevel.verbose,
};

String _formatRustLogMessage(xelis.XelisLogEntry entry) {
  final source = entry.source.name;
  if (!diagnosticLoggingEnabled) {
    return 'source=$source ${entry.message}';
  }
  return 'source=$source target=${entry.target}\n${entry.message}';
}

final _rustLoggingController = _RustLoggingController(
  initializeLogger: () => xelis.XelisWalletFlutter.initializeRustLogger(
    minimumLevel: _rustTraceEnabled
        ? xelis.XelisLogLevel.trace
        : diagnosticLoggingEnabled
        ? xelis.XelisLogLevel.debug
        : xelis.XelisLogLevel.warn,
    diagnosticMode: diagnosticLoggingEnabled,
  ),
  createLogStream: xelis.XelisWalletFlutter.createRustLogStream,
  onEntry: (entry) {
    final logLevel = _mapLogLevel(entry.level);
    talker.logCustom(
      TalkerLog(
        _formatRustLogMessage(entry),
        key: diagnosticLoggingEnabled
            ? TalkerKey.fromLogLevel(logLevel)
            : supportLogKey,
        title: 'Rust/${entry.source.name}',
        logLevel: logLevel,
      ),
    );
  },
  onError: (error, stackTrace) {
    logSupportEvent(
      AppSupportEvent.rustLogStreamFailed,
      diagnosticContext: 'errorType=${error.runtimeType}',
      stackTrace: stackTrace,
    );
  },
);

Future<void> initRustLogging() async {
  try {
    await _rustLoggingController.start();
  } catch (error, stackTrace) {
    logSupportEvent(
      AppSupportEvent.rustLoggerInitializationFailed,
      diagnosticContext: 'errorType=${error.runtimeType}',
      stackTrace: stackTrace,
    );
  }
}

Future<void> disposeRustLogging() => _rustLoggingController.stop();

final class _RustLoggingController {
  _RustLoggingController({
    required this.initializeLogger,
    required this.createLogStream,
    required this.onEntry,
    required this.onError,
  });

  final Future<void> Function() initializeLogger;
  final Stream<xelis.XelisLogEntry> Function() createLogStream;
  final void Function(xelis.XelisLogEntry entry) onEntry;
  final void Function(Object error, StackTrace stackTrace) onError;

  Future<void>? _startFuture;
  Future<void>? _stopFuture;
  StreamSubscription<xelis.XelisLogEntry>? _subscription;
  Object? _streamToken;
  int _generation = 0;

  Future<void> start() {
    final stopFuture = _stopFuture;
    if (stopFuture != null) {
      return stopFuture.then((_) => start());
    }

    if (_subscription != null) return Future<void>.value();

    final startFuture = _startFuture;
    if (startFuture != null) return startFuture;

    final generation = _generation;
    late final Future<void> trackedStart;
    trackedStart = _start(generation).whenComplete(() {
      if (identical(_startFuture, trackedStart) && _subscription == null) {
        _startFuture = null;
      }
    });
    _startFuture = trackedStart;
    return trackedStart;
  }

  Future<void> _start(int generation) async {
    await initializeLogger();
    if (generation != _generation) return;

    final token = Object();
    _streamToken = token;
    final subscription = createLogStream().listen(
      onEntry,
      onError: (Object error, StackTrace stackTrace) {
        onError(error, stackTrace);
      },
      onDone: () => _handleDone(token),
      cancelOnError: false,
    );

    if (!identical(_streamToken, token)) {
      await subscription.cancel();
      return;
    }
    _subscription = subscription;
  }

  void _handleDone(Object token) {
    if (!identical(_streamToken, token)) return;

    _streamToken = null;
    _subscription = null;
    _startFuture = null;
    _generation++;
  }

  Future<void> stop() {
    final stopFuture = _stopFuture;
    if (stopFuture != null) return stopFuture;

    late final Future<void> trackedStop;
    trackedStop = _stop().whenComplete(() {
      if (identical(_stopFuture, trackedStop)) {
        _stopFuture = null;
      }
    });
    _stopFuture = trackedStop;
    return trackedStop;
  }

  Future<void> _stop() async {
    _generation++;
    _streamToken = null;

    final startFuture = _startFuture;
    if (startFuture != null) {
      try {
        await startFuture;
      } catch (_) {
        // A failed start is already surfaced by initRustLogging.
      }
    }
    _startFuture = null;

    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}
