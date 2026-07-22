import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_participant_editor.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_threshold_selector.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

class MultisigSetupConfiguration extends StatelessWidget {
  const MultisigSetupConfiguration({
    required this.loc,
    required this.participants,
    required this.threshold,
    required this.isPreparing,
    required this.validateParticipant,
    required this.onParticipantsChanged,
    required this.onThresholdChanged,
    required this.onPrepare,
    super.key,
  });

  final AppLocalizations loc;
  final List<String> participants;
  final int threshold;
  final bool isPreparing;
  final String? Function(String address) validateParticipant;
  final ValueChanged<List<String>> onParticipantsChanged;
  final ValueChanged<int> onThresholdChanged;
  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalLayout =
            constraints.maxWidth >= context.theme.breakpoints.md;
        final participantEditor = MultisigParticipantEditor(
          loc: loc,
          initialParticipants: participants,
          enabled: !isPreparing,
          validateAddress: validateParticipant,
          onChanged: onParticipantsChanged,
        );
        final thresholdSelector = MultisigThresholdSelector(
          loc: loc,
          threshold: threshold,
          participantCount: participants.length,
          enabled: !isPreparing,
          onChanged: onThresholdChanged,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.large,
          children: [
            _ConfigurationHeader(loc: loc),
            FAlert(
              title: Text(loc.warning),
              subtitle: Text(loc.multisig_setup_warning),
            ),
            if (useHorizontalLayout)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: participantEditor),
                  const SizedBox(width: Spaces.large),
                  Expanded(flex: 2, child: thresholdSelector),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.large,
                children: [participantEditor, thresholdSelector],
              ),
            _ConfigurationAction(
              loc: loc,
              isPreparing: isPreparing,
              enabled: participants.isNotEmpty,
              expand: context.isCompactLayout,
              onPrepare: onPrepare,
            ),
          ],
        );
      },
    );
  }
}

class _ConfigurationHeader extends StatelessWidget {
  const _ConfigurationHeader({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.small,
      children: [
        FBadge(
          variant: .outline,
          child: Text(loc.multisig_setup_step_configuration),
        ),
        Text(
          loc.multisig_setup_title,
          style: context.theme.typography.display.xl2,
        ),
        Text(
          loc.multisig_setup_description,
          style: context.theme.typography.body.md.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _ConfigurationAction extends StatelessWidget {
  const _ConfigurationAction({
    required this.loc,
    required this.isPreparing,
    required this.enabled,
    required this.expand,
    required this.onPrepare,
  });

  final AppLocalizations loc;
  final bool isPreparing;
  final bool enabled;
  final bool expand;
  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context) {
    final button = AsyncFButton(
      isLoading: isPreparing,
      onPress: enabled && !isPreparing ? onPrepare : null,
      prefix: const Icon(FLucideIcons.arrowRight, size: 18),
      child: Text(loc.multisig_setup_review_configuration),
    );

    return expand
        ? SizedBox(width: double.infinity, child: button)
        : Align(alignment: Alignment.centerRight, child: button);
  }
}
