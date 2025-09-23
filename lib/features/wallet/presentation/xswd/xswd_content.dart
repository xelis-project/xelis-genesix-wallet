import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';

class XSWDContent extends ConsumerStatefulWidget {
  const XSWDContent({super.key});

  @override
  ConsumerState createState() => _XSWDContentState();
}

class _XSWDContentState extends ConsumerState<XSWDContent> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadedScroll(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Placeholder(),
      ),
    );
  }
}
