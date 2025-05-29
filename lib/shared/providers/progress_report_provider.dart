import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/src/generated/rust_bridge/api/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/src/generated/rust_bridge/api/progress_report.dart';

part 'progress_report_provider.g.dart';

@riverpod
Stream<ProgressReport> progressReportStream(Ref ref) {
  return createProgressReportStream();
}
