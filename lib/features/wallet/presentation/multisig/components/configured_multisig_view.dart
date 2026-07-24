import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_participant.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ConfiguredMultisigView extends StatelessWidget {
  const ConfiguredMultisigView({
    required this.loc,
    required this.state,
    required this.scrollController,
    required this.onCopyParticipant,
    required this.isDeleting,
    required this.onDelete,
    super.key,
  });

  final AppLocalizations loc;
  final MultisigState state;
  final ScrollController scrollController;
  final ValueChanged<String> onCopyParticipant;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final participants = state.participants.toList(growable: false)
      ..sort((a, b) => a.id.compareTo(b.id));
    final formattedTopoheight = NumberFormat.decimalPattern().format(
      state.topoheight,
    );

    return Padding(
      padding: const EdgeInsets.all(Spaces.medium),
      child: FadedScroll(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.extraLarge,
                children: [
                  _ConfiguredMultisigHeader(loc: loc),
                  AppCard(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: Spaces.large,
                      children: [
                        Text(
                          loc.multisig_setup_summary_title,
                          style: context.theme.typography.display.md,
                        ),
                        _MultisigMetrics(
                          loc: loc,
                          threshold: state.threshold,
                          participantCount: participants.length,
                          activationHeight: formattedTopoheight,
                        ),
                      ],
                    ),
                  ),
                  AppCard(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: Spaces.smallMedium,
                      children: [
                        Text(
                          loc.multisig_authorized_wallets,
                          style: context.theme.typography.display.md,
                        ),
                        _MultisigParticipantList(
                          loc: loc,
                          participants: participants,
                          onCopyParticipant: onCopyParticipant,
                        ),
                      ],
                    ),
                  ),
                  _DeleteMultisigSection(
                    loc: loc,
                    isDeleting: isDeleting,
                    onDelete: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfiguredMultisigHeader extends StatelessWidget {
  const _ConfiguredMultisigHeader({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.small,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: [
            Text(loc.multisig, style: context.theme.typography.display.lg),
            FBadge(child: Text(loc.enabled)),
          ],
        ),
        Text(
          loc.multisig_active_description,
          style: context.theme.typography.body.md.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _MultisigMetrics extends StatelessWidget {
  const _MultisigMetrics({
    required this.loc,
    required this.threshold,
    required this.participantCount,
    required this.activationHeight,
  });

  final AppLocalizations loc;
  final int threshold;
  final int participantCount;
  final String activationHeight;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        icon: FLucideIcons.keyRound,
        title: loc.multisig_setup_threshold_label,
        value: threshold.toString(),
      ),
      (
        icon: FLucideIcons.users,
        title: loc.participants,
        value: participantCount.toString(),
      ),
      (
        icon: FLucideIcons.blocks,
        title: loc.multisig_activation_height,
        value: activationHeight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < context.theme.breakpoints.sm) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spaces.large,
            children: [
              for (final metric in metrics)
                _MultisigMetric(
                  icon: metric.icon,
                  title: metric.title,
                  value: metric.value,
                  compact: true,
                ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, metric) in metrics.indexed) ...[
                Expanded(
                  child: _MultisigMetric(
                    icon: metric.icon,
                    title: metric.title,
                    value: metric.value,
                  ),
                ),
                if (index != metrics.length - 1)
                  const FDivider(axis: .vertical),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MultisigMetric extends StatelessWidget {
  const _MultisigMetric({
    required this.icon,
    required this.title,
    required this.value,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final metric = LabeledValue.text(
      title,
      value,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: context.theme.typography.display.md,
    );

    if (compact) {
      return Row(
        children: [
          _MetricIcon(icon: icon),
          const SizedBox(width: Spaces.smallMedium),
          Expanded(child: metric),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: Spaces.smallMedium,
      children: [
        _MetricIcon(icon: icon),
        metric,
      ],
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.theme.colors.primary.withValues(alpha: 0.1),
        borderRadius: context.theme.style.borderRadius.md,
      ),
      child: Icon(icon, size: 20, color: context.theme.colors.primary),
    );
  }
}

class _MultisigParticipantList extends StatelessWidget {
  const _MultisigParticipantList({
    required this.loc,
    required this.participants,
    required this.onCopyParticipant,
  });

  final AppLocalizations loc;
  final List<MultisigParticipant> participants;
  final ValueChanged<String> onCopyParticipant;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in participants.indexed) ...[
          _MultisigParticipantTile(
            participant: entry.$2,
            copyLabel: loc.copy,
            onCopy: onCopyParticipant,
          ),
          if (entry.$1 != participants.length - 1) const FDivider(),
        ],
      ],
    );
  }
}

class _MultisigParticipantTile extends StatelessWidget {
  const _MultisigParticipantTile({
    required this.participant,
    required this.copyLabel,
    required this.onCopy,
  });

  final MultisigParticipant participant;
  final String copyLabel;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.smallMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FBadge(variant: .outline, child: Text('#${participant.id + 1}')),
          const SizedBox(width: Spaces.smallMedium),
          Expanded(
            child: AddressWidget(
              participant.address,
              compact: context.isCompactLayout,
            ),
          ),
          const SizedBox(width: Spaces.small),
          FTooltip(
            tipBuilder: (context, controller) => Text(copyLabel),
            child: FButton.icon(
              variant: .ghost,
              onPress: () => onCopy(participant.address),
              child: const Icon(FLucideIcons.copy, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteMultisigSection extends StatelessWidget {
  const _DeleteMultisigSection({
    required this.loc,
    required this.isDeleting,
    required this.onDelete,
  });

  final AppLocalizations loc;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final button = AsyncFButton(
      isLoading: isDeleting,
      variant: .destructive,
      prefix: const Icon(FLucideIcons.trash),
      onPress: isDeleting ? null : onDelete,
      child: Text(loc.delete_multisig_configuration),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.medium,
      children: [
        FAlert(
          icon: const Icon(FLucideIcons.info),
          title: Text(loc.multisig_removal),
          subtitle: Text(loc.multisig_delete_description),
        ),
        SizedBox(width: double.infinity, child: button),
      ],
    );
  }
}
