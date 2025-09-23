import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/src/generated/rust_bridge/api/logger.dart' as frb;
import 'package:genesix/src/generated/rust_bridge/api/api.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_settings.dart';

// Global Talker instance
final talker = TalkerFlutter.init();

// Keep a single subscription to avoid duplicate logs
StreamSubscription<dynamic>? _rustLogSubscription;
bool _rustLoggingInitialized = false;

// Providers to exclude in debug (reduce noise)
const Set<String> _debugExcludedProviders = {
  'xelisPriceProvider', // noisy in debug
};

const Set<String> _releaseExcludedProviders = {
  // keep minimal in release (add noisy providers here if needed)
  'xelisPriceProvider',
  // excluded for privacy reasons
  'walletStateProvider',
  'historyProvider',
  'lastTransactionsProvider'
};

// Build Riverpod logger settings based on build mode
TalkerRiverpodLoggerSettings _riverpodLoggerSettings({required bool verbose}) {
  return TalkerRiverpodLoggerSettings(
    printProviderDisposed: verbose,
    printStateFullData: verbose,
    providerFilter: (provider) {
      // Select exclusion set based on build mode
      final excludes = kReleaseMode
          ? _releaseExcludedProviders
          : _debugExcludedProviders;

      // Include everything except what is explicitly excluded
      return !excludes.contains(provider.name);
    },
  );
}

// Provide Riverpod observers for logging
List<ProviderObserver> riverpodObserversMinimal() {
  final verbose = kDebugMode;
  return [
    TalkerRiverpodObserver(
      talker: talker,
      settings: _riverpodLoggerSettings(verbose: verbose),
    ),
  ];
}

// Map Rust log level to Talker log level
LogLevel _mapLogLevel(frb.Level level) {
  switch (level) {
    case frb.Level.error:
      return LogLevel.error;
    case frb.Level.warn:
      return LogLevel.warning;
    case frb.Level.info:
      return LogLevel.info;
    case frb.Level.debug:
      return LogLevel.debug;
    case frb.Level.trace:
      return LogLevel.verbose;
  }
}

// Normalize tag across OS and format the message consistently
String _formatRustLogMessage({required String tag, required String msg}) {
  // Normalize Windows '\' to '/' to make parsing stable
  final normalized = tag.replaceAll('\\', '/');
  // Try to split around ".cargo" boundary if present
  final parts = normalized.split('/.cargo/');
  final scope = parts.length > 1 ? 'LIB: ${parts.last}' : 'BRIDGE: $normalized';
  return '\n$scope\n$msg';
}

// Initialize Rust -> Talker logging once
Future<void> initRustLogging() async {
  if (_rustLoggingInitialized) return;

  try {
    await setUpRustLogger();
    _rustLogSubscription = createLogStream().listen(
      (event) {
        final logLevel = _mapLogLevel(event.level);
        final message = _formatRustLogMessage(tag: event.tag, msg: event.msg);

        talker.logCustom(TalkerLog(title: 'Rust', message, logLevel: logLevel));
      },
      onError: (Object error, StackTrace stack) {
        talker.error('Rust log stream error', error, stack);
      },
      cancelOnError: false, // keep listening even if a single event fails
    );

    _rustLoggingInitialized = true;
  } catch (e, st) {
    talker.error('Failed to initialize Rust logging', e, st);
  }
}

// Dispose Rust logging subscription and disable Talker
Future<void> disposeRustLogging() async {
  try {
    await _rustLogSubscription?.cancel();
    talker.disable();
  } finally {
    _rustLogSubscription = null;
    _rustLoggingInitialized = false;
  }
}
