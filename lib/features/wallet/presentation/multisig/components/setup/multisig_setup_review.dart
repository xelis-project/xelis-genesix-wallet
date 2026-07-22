import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

class MultisigSetupReview extends StatelessWidget {
  const MultisigSetupReview({
    required this.loc,
    required this.hash,
    required this.fee,
    required this.threshold,
    required this.participants,
    required this.confirmed,
    required this.isBroadcasting,
    required this.onConfirmationChanged,
    required this.onEdit,
    required this.onActivate,
    super.key,
  });

  final AppLocalizations loc;
  final String hash;
  final String fee;
  final int threshold;
  final List<String> participants;
  final bool confirmed;
  final bool isBroadcasting;
  final ValueChanged<bool> onConfirmationChanged;
  final VoidCallback onEdit;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        _ReviewHeader(loc: loc),
        _ConfigurationSummary(
          loc: loc,
          hash: hash,
          fee: fee,
          threshold: threshold,
          participantCount: participants.length,
        ),
        _ReviewParticipants(loc: loc, participants: participants),
        FCheckbox(
          value: confirmed,
          enabled: !isBroadcasting,
          onChange: isBroadcasting ? null : onConfirmationChanged,
          label: Text(loc.multisig_setup_review_confirmation),
        ),
        _ReviewActions(
          loc: loc,
          confirmed: confirmed,
          isBroadcasting: isBroadcasting,
          expand: context.isCompactLayout,
          onEdit: onEdit,
          onActivate: onActivate,
        ),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.small,
      children: [
        FBadge(variant: .outline, child: Text(loc.multisig_setup_step_review)),
        Text(
          loc.multisig_setup_review_title,
          style: context.theme.typography.display.xl2,
        ),
        Text(
          loc.multisig_setup_review_description,
          style: context.theme.typography.body.md.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _ConfigurationSummary extends StatelessWidget {
  const _ConfigurationSummary({
    required this.loc,
    required this.hash,
    required this.fee,
    required this.threshold,
    required this.participantCount,
  });

  final AppLocalizations loc;
  final String hash;
  final String fee;
  final int threshold;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: Text(loc.multisig_setup_summary_title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.medium,
        children: [
          _ThresholdMetric(
            loc: loc,
            threshold: threshold,
            participantCount: participantCount,
          ),
          const FDivider(),
          _ReviewValue(label: loc.fee, value: fee),
          _ReviewValue(label: loc.hash, value: hash, selectable: true),
        ],
      ),
    );
  }
}

class _ThresholdMetric extends StatelessWidget {
  const _ThresholdMetric({
    required this.loc,
    required this.threshold,
    required this.participantCount,
  });

  final AppLocalizations loc;
  final int threshold;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.theme.colors.primary.withValues(alpha: 0.1),
            borderRadius: context.theme.style.borderRadius.md,
          ),
          child: Icon(
            FLucideIcons.keyRound,
            size: 22,
            color: context.theme.colors.primary,
          ),
        ),
        const SizedBox(width: Spaces.smallMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spaces.extraSmall,
            children: [
              Text(
                '$threshold / $participantCount',
                style: context.theme.typography.display.lg,
              ),
              Text(
                loc.multisig_setup_threshold_summary(
                  threshold,
                  participantCount,
                ),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewValue extends StatelessWidget {
  const _ReviewValue({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final style = context.theme.typography.body.sm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.extraSmall,
      children: [
        Text(
          label,
          style: style.copyWith(color: context.theme.colors.mutedForeground),
        ),
        if (selectable)
          SelectableText(value, style: style)
        else
          Text(value, style: style),
      ],
    );
  }
}

class _ReviewParticipants extends StatelessWidget {
  const _ReviewParticipants({required this.loc, required this.participants});

  final AppLocalizations loc;
  final List<String> participants;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: Text(loc.participants),
      subtitle: Text(loc.multisig_setup_participant_count(participants.length)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.smallMedium,
        children: [
          for (final (index, address) in participants.indexed)
            _ReviewParticipant(index: index, address: address),
        ],
      ),
    );
  }
}

class _ReviewParticipant extends StatelessWidget {
  const _ReviewParticipant({required this.index, required this.address});

  final int index;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FBadge(variant: .outline, child: Text('#${index + 1}')),
        const SizedBox(width: Spaces.small),
        Expanded(child: AddressWidget(address)),
      ],
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.loc,
    required this.confirmed,
    required this.isBroadcasting,
    required this.expand,
    required this.onEdit,
    required this.onActivate,
  });

  final AppLocalizations loc;
  final bool confirmed;
  final bool isBroadcasting;
  final bool expand;
  final VoidCallback onEdit;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final edit = FButton(
      variant: .outline,
      onPress: isBroadcasting ? null : onEdit,
      child: Text(loc.edit_button),
    );
    final activate = AsyncFButton(
      isLoading: isBroadcasting,
      onPress: confirmed && !isBroadcasting ? onActivate : null,
      prefix: const Icon(FLucideIcons.shieldCheck, size: 18),
      child: Text(loc.multisig_setup_activate),
    );

    if (expand) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.small,
        children: [edit, activate],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      children: [edit, activate],
    );
  }
}
