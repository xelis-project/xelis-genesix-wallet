import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';

class ConfirmDialog extends ConsumerStatefulWidget {
  final String? title;
  final String? description;
  final void Function(bool yes) onConfirm;
  final FDialogStyle style;
  final Animation<double> animation;

  const ConfirmDialog({
    required this.style,
    required this.animation,
    required this.onConfirm,
    this.title,
    this.description,
    super.key,
  });

  @override
  ConsumerState<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends ConsumerState<ConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    var title = widget.title ?? loc.are_you_sure;

    return FDialog(
      direction: Axis.horizontal,
      title: Text(title),
      body: widget.description != null ? Text(widget.description!) : null,
      actions: [
        FButton(
          variant: .outline,
          onPress: () {
            context.pop();
            widget.onConfirm(false);
          },
          child: Text(loc.cancel_button),
        ),
        FButton(
          onPress: () {
            context.pop();
            widget.onConfirm(true);
          },
          child: Text(loc.confirm_button),
        ),
      ],
    );
  }
}
