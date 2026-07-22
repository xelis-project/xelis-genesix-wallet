import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

class BroadcastComplete extends ConsumerWidget {
  const BroadcastComplete({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      key: const ValueKey('broadcast-complete'),
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Spaces.large,
              children: [
                Icon(
                  FLucideIcons.circleCheckBig,
                  size: 72,
                  color: context.theme.colors.primary,
                ),
                Text(
                  loc.transaction_broadcast_message,
                  textAlign: TextAlign.center,
                  style: context.theme.typography.display.xl,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spaces.medium),
        _BottomCloseButton(label: loc.close, onClose: onClose),
      ],
    );
  }
}

class EmptyReview extends ConsumerWidget {
  const EmptyReview({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Spaces.large,
              children: [
                const Icon(FLucideIcons.fileQuestion, size: 64),
                Text(loc.no_data, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spaces.medium),
        _BottomCloseButton(label: loc.close, onClose: onClose),
      ],
    );
  }
}

class _BottomCloseButton extends StatelessWidget {
  const _BottomCloseButton({required this.label, required this.onClose});

  final String label;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(
          width: double.infinity,
          child: FButton(onPress: onClose, child: Text(label)),
        ),
      ),
    );
  }
}
