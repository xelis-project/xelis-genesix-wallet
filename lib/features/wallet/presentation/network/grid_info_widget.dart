import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class GridInfoWidget extends StatelessWidget {
  const GridInfoWidget({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: context.theme.style.borderRadius,
        border: Border.all(
          color: context.theme.colors.muted,
          width: context.theme.style.borderWidth,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: items,
      ),
    );
  }
}
