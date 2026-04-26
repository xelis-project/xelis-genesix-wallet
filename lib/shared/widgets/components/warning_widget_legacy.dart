import 'package:flutter/material.dart';
import 'package:genesix/shared/theme/constants.dart';

class WarningWidget extends StatelessWidget {
  const WarningWidget(this.messages, {super.key});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: messages.map((m) => Text(m)).toList(),
      ),
    );
  }
}
