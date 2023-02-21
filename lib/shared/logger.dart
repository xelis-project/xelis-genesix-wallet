import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final logger = Logger('XelisWalletApp');

void initLogging() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    // if (kDebugMode) {
    //   print('${record.level.name}: ${record.time}: ${record.message}');
    // }
  });
}
