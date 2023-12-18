import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NodeTab extends ConsumerStatefulWidget {
  const NodeTab({super.key});

  @override
  ConsumerState createState() => _NodeTabWidgetState();
}

class _NodeTabWidgetState extends ConsumerState<NodeTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'NODE TAB',
        style: context.displayMedium,
      ),
    );
  }
}
