import 'package:flutter/material.dart';
import 'package:genesix/features/logger/presentation/logger_view.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LoggerScreen extends StatelessWidget {
  const LoggerScreen({super.key, required this.talker});

  final Talker talker;

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: Colors.transparent,
      body: LoggerView(
        talker: talker,
        theme: TalkerScreenTheme(
          backgroundColor: context.colors.surface,
          textColor: context.colors.onSurface,
          logColors: {
            TalkerLogType.debug.name: const Color(0xFF56FEA8),
            TalkerLogType.riverpodAdd.name: Colors.blue,
            TalkerLogType.riverpodUpdate.name: const Color(0xFF63FAFE),
            TalkerLogType.riverpodDispose.name: const Color(0xFFFF005F),
            TalkerLogType.riverpodFail.name: const Color.fromARGB(
              255,
              198,
              40,
              40,
            ),
          },
        ),
      ),
    );
  }
}
