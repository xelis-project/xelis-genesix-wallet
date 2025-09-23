import 'package:flutter/material.dart';
import 'package:genesix/src/generated/rust_bridge/api/logger.dart';
import 'package:genesix/src/generated/rust_bridge/api/api.dart';
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
        talker.logCustom(
          TalkerLog(title: 'Rust-Error', message, logLevel: LogLevel.error),
        );
      case Level.warn:
        talker.logCustom(
          TalkerLog(title: 'Rust-Warning', message, logLevel: LogLevel.warning),
        );
      case Level.info:
        talker.logCustom(
          TalkerLog(title: 'Rust-Info', message, logLevel: LogLevel.info),
        );
      case Level.debug:
        talker.logCustom(
          TalkerLog(title: 'Rust-Debug', message, logLevel: LogLevel.debug),
        );
      case Level.trace:
        talker.logCustom(
          TalkerLog(title: 'Rust-Trace', message, logLevel: LogLevel.verbose),
        );
    }
  });
}
