import 'dart:async';

import 'package:genesix/rust_bridge/api/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/rust_bridge/api/progress_report.dart';

part 'progress_report_provider.g.dart';

@riverpod
Stream<Report> progressReportStream(ProgressReportStreamRef ref) {
  return createProgressReportStream();
}

@riverpod
Raw<Stream<Report_TableGeneration>> tableGenerationProgress(
    TableGenerationProgressRef ref) async* {
  final report = ref.watch(progressReportStreamProvider);
  switch (report) {
    // TODO
    // case AsyncValue(:final error?):
    //   {}
    case AsyncValue(valueOrNull: final value):
      {
        switch (value) {
          case Report_TableGeneration():
            yield value;
          case Report_Misc():
          case null:
        }
      }
  }
}
