import 'package:flutter/material.dart';
import 'package:genesix/rust_bridge/api/logger.dart';
import 'package:genesix/rust_bridge/api/api.dart';
import 'package:talker_flutter/talker_flutter.dart';

// Talker instance to log messages
final talker = TalkerFlutter.init();

// Redirection of Rust logs to Talker
Future<void> initRustLogging() async {
  await setUpRustLogger();
  createLogStream().listen((event) {
    final source = event.tag.split('\\.cargo\\');

    String message;
    if (source.length < 2) {
      message = '\nBRIDGE: ${source.first}\n${event.msg}';
    } else {
      message = '\nLIB: ${source[1]}\n${event.msg}';
    }

    switch (event.level) {
      case Level.error:
        talker.logTyped(
            TalkerLog(title: 'Rust-Error', message, logLevel: LogLevel.error));
      case Level.warn:
        talker.logTyped(TalkerLog(
            title: 'Rust-Warning', message, logLevel: LogLevel.warning));
      case Level.info:
        talker.logTyped(
            TalkerLog(title: 'Rust-Info', message, logLevel: LogLevel.info));
      case Level.debug:
        talker.logTyped(TalkerLog(
          title: 'Rust-Debug',
          message,
          logLevel: LogLevel.debug,
        ));
      case Level.trace:
        talker.logTyped(TalkerLog(
            title: 'Rust-Trace', message, logLevel: LogLevel.verbose));
    }
  });
}

// Extension to get the color of the log message
extension TalkerDataRust on TalkerData {
  Color getColor(TalkerScreenTheme theme) {
    final level = logLevel;
    final key = this.key;

    Color? color;
    if (key == null && level != null) {
      color = theme.logColors[TalkerLogType.fromLogLevel(level)];
    } else if (key != null) {
      color = theme.logColors[TalkerLogType.fromKey(key)];
    }

    return color ?? Colors.grey;
  }
}
