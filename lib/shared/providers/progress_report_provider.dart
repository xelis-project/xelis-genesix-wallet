import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'progress_report_provider.g.dart';

@riverpod
Stream<ProgressReport> progressReportStream(Ref ref) {
  return XelisWalletFlutter.createProgressReportStream();
}
