import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';

class RecoveryPhraseDialog extends ConsumerStatefulWidget {
  const RecoveryPhraseDialog(
    this.style,
    this.animation,
    this.seed, {
    super.key,
  });

  final String seed;
  final FDialogStyle style;
  final Animation<double> animation;

  @override
  ConsumerState<RecoveryPhraseDialog> createState() =>
      _RecoveryPhraseDialogState();
}

class _RecoveryPhraseDialogState extends ConsumerState<RecoveryPhraseDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final words = widget.seed.split(' ');

    return FDialog(
      style: widget.style.call,
      animation: widget.animation,
      title: Row(
        children: [
          Expanded(child: Text('My ${loc.recovery_phrase}')),
          FTooltip(
            tipBuilder: (context, controller) => Text(loc.copy_recovery_phrase),
            child: FButton.icon(
              onPress: () => copyToClipboard(widget.seed, ref, loc.copied),
              child: Icon(FIcons.copy),
            ),
          ),
        ],
      ),
      direction: Axis.horizontal,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Spaces.medium),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.mediaHeight * 0.4),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  words.length,
                  (i) => FBadge(
                    style: FBadgeStyle.secondary(),
                    child: Row(
                      children: [
                        Text(
                          '${i + 1}.',
                          style: context.theme.typography.sm.copyWith(
                            color: context.theme.colors.primary,
                          ),
                        ),
                        const SizedBox(width: Spaces.small),
                        Text(words[i]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spaces.large),
          Flexible(
            child: FCheckbox(
              label: const Text('Recovery Phrase Acknowledgement'),
              description: const Text(
                'You understand that if you lose or share your recovery phrase, all funds in this wallet may be lost permanently.',
              ),
              value: _confirmed,
              onChange: (value) => setState(() => _confirmed = value),
            ),
          ),
        ],
      ),
      actions: [
        FButton(
          onPress: _confirmed
              ? () {
                  context.pop();
                }
              : null,
          child: Text(loc.continue_button),
        ),
      ],
    );
  }
}
