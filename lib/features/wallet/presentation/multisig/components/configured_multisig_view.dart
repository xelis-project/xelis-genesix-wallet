import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_participant.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
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
    required this.onDelete,
    super.key,
  });

  final AppLocalizations loc;
  final MultisigState state;
  final ScrollController scrollController;
  final ValueChanged<String> onCopyParticipant;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final participants = state.participants.toList(growable: false);
    final formattedTopoheight = NumberFormat.decimalPattern().format(
      state.topoheight,
    );

    return Padding(
      padding: const EdgeInsets.all(Spaces.medium),
      child: FadedScroll(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spaces.extraLarge,
            children: [
              _ConfiguredMultisigHeader(loc: loc),
              AppCard(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  spacing: Spaces.large,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.information,
                      style: context.theme.typography.body.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    Wrap(
                      spacing: Spaces.large,
                      runSpacing: Spaces.large,
                      children: [
                        SizedBox(
                          width: 200,
                          child: _MultisigMetric(
                            title: loc.threshold,
                            value: '${state.threshold}/${participants.length}',
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: _MultisigMetric(
                            title: loc.participants,
                            value: participants.length.toString(),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: _MultisigMetric(
                            title: loc.topoheight,
                            value: formattedTopoheight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppCard(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  spacing: Spaces.large,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Spaces.small,
                      children: [
                        Text(
                          loc.participants,
                          style: context.theme.typography.body.md.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          loc.multisig_setup_message_1,
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    _MultisigParticipantList(
                      loc: loc,
                      participants: participants,
                      onCopyParticipant: onCopyParticipant,
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FButton(
                  variant: .destructive,
                  prefix: const Icon(FLucideIcons.trash),
                  onPress: onDelete,
                  child: Text(loc.delete_multisig_configuration),
                ),
              ),
            ],
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
        Text(loc.multisig, style: context.theme.typography.display.xl3),
        Text(
          loc.multisig_setup_confirmation_message,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _MultisigMetric extends StatelessWidget {
  const _MultisigMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LabeledValue.text(
      title,
      value,
      style: context.theme.typography.body.lg.copyWith(
        fontWeight: FontWeight.w600,
      ),
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
    if (participants.isEmpty) {
      return _EmptyParticipantsNotice(
        message: loc.no_multisig_configuration_found,
      );
    }

    return Column(
      spacing: Spaces.medium,
      children: [
        for (final entry in participants.indexed) ...[
          _MultisigParticipantTile(
            index: entry.$1,
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

class _EmptyParticipantsNotice extends StatelessWidget {
  const _EmptyParticipantsNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        borderRadius: BorderRadius.circular(Spaces.medium),
        border: Border.all(color: context.theme.colors.border),
      ),
      child: Text(
        message,
        style: context.theme.typography.body.md.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

class _MultisigParticipantTile extends StatelessWidget {
  const _MultisigParticipantTile({
    required this.index,
    required this.participant,
    required this.copyLabel,
    required this.onCopy,
  });

  final int index;
  final MultisigParticipant participant;
  final String copyLabel;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        borderRadius: BorderRadius.circular(Spaces.medium),
        border: Border.all(color: context.theme.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spaces.medium,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FBadge(variant: .outline, child: Text('#${index + 1}')),
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onCopy(participant.address),
            child: AddressWidget(participant.address),
          ),
        ],
      ),
    );
  }
}
