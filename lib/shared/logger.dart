import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:xelis_mobile_wallet/src/rust/api/api.dart';

final logger = Logger('XelisWalletApp');

void initFlutterLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
        '${record.level.name}: ${DateFormat('yyyy-MM-dd H:m:s.S').format(record.time)} - ${record.message}');
  });
}

Future<void> initRustLogging() async {
  await setUpRustLogger();
  createLogStream().listen((event) {
    final time = DateTime.fromMillisecondsSinceEpoch(event.timeMillis);
    debugPrint('${event.level}: $time - ${event.tag} - ${event.msg}');
  });
}

class LoggerProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('''
{
  "provider": "${provider.name ?? provider.runtimeType}",
  "newValue": "$newValue"
}''');
  }
}
