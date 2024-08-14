import 'package:flutter/material.dart';
import 'package:genesix/features/logger/presentation/logger_view.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';
import 'package:talker_flutter/talker_flutter.dart';

class LoggerScreen extends StatelessWidget {
  const LoggerScreen({super.key, required this.talker});

  final Talker talker;

  @override
  Widget build(BuildContext context) {
    return Background(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: LoggerView(
        talker: talker,
        theme: TalkerScreenTheme(
          backgroundColor: context.colors.surface,
          textColor: context.colors.onSurface,
          logColors: {
            TalkerLogType.debug: const Color(0xFF56FEA8),
            TalkerLogType.riverpodAdd: Colors.blue,
            TalkerLogType.riverpodUpdate: const Color(0xFF63FAFE),
            TalkerLogType.riverpodDispose: const Color(0xFFFF005F),
            TalkerLogType.riverpodFail: const Color.fromARGB(255, 198, 40, 40),
          },
        ),
      ),
    ));
  }
}
