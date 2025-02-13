import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';

class ConfirmDialog extends ConsumerStatefulWidget {
  final String? title;
  final void Function(bool yes) onConfirm;

  const ConfirmDialog({this.title, required this.onConfirm, super.key});

  @override
  ConsumerState<ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends ConsumerState<ConfirmDialog> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    var title = widget.title ?? loc.are_you_sure;

    return GenericDialog(
      scrollable: false,
      content: Text(title, style: context.titleMedium),
      actions: [
        TextButton(
          onPressed: () {
            context.pop();
            widget.onConfirm(false);
          },
          child: Text(loc.no),
        ),
        TextButton(
          onPressed: () {
            context.pop();
            widget.onConfirm(true);
          },
          child: Text(loc.yes),
        ),
      ],
    );
  }
}
