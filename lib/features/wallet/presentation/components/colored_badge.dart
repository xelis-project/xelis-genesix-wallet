import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class ColoredBadge extends StatelessWidget {
  ColoredBadge.flag(Flag flag, {super.key})
    : text = flag.name.capitalize(),
      color = flagColor(flag);

  ColoredBadge.label(String label, {super.key})
    : text = label,
      color = labelColor(label);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.40);

    return FBadge(
      style: .delta(
        decoration: .delta(color: bg),
        contentStyle: .delta(labelTextStyle: .delta(color: color)),
      ),
      child: Text(text),
    );
  }
}

Color flagColor(Flag f) {
  switch (f) {
    case Flag.private:
      return Colors.indigo.shade400;
    case Flag.public:
      return Colors.cyan.shade400;
    case Flag.proprietary:
      return Colors.pink.shade300;
    case Flag.failed:
      return Colors.red.shade500;
  }
}

Color labelColor(String label) {
  switch (label) {
    case 'JSON':
      return Colors.lime.shade500;
    case 'Text':
      return Colors.blueGrey.shade400;
    case 'UTF-8':
      return Colors.lightBlue.shade400;
    case 'Bytes':
      return Colors.purple.shade300;
    default:
      return Colors.blueGrey.shade400;
  }
}
