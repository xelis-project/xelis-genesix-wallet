import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_setup_animated_switcher.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

Duration _thresholdMotionDuration(BuildContext context) {
  final animationsDisabled =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return animationsDisabled
      ? Duration.zero
      : const Duration(milliseconds: AppDurations.animNormal);
}

class MultisigThresholdSelector extends StatelessWidget {
  const MultisigThresholdSelector({
    required this.loc,
    required this.threshold,
    required this.participantCount,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final AppLocalizations loc;
  final int threshold;
  final int participantCount;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: Text(loc.threshold),
      subtitle: Text(loc.multisig_setup_threshold_description),
      child: MultisigSetupAnimatedSwitcher(
        duration: _thresholdMotionDuration(context),
        child: participantCount == 0
            ? _EmptyThreshold(key: const ValueKey('empty-threshold'), loc: loc)
            : _ConfiguredThreshold(
                key: const ValueKey('configured-threshold'),
                loc: loc,
                threshold: threshold,
                participantCount: participantCount,
                enabled: enabled,
                onChanged: onChanged,
              ),
      ),
    );
  }
}

class _ConfiguredThreshold extends StatelessWidget {
  const _ConfiguredThreshold({
    required this.loc,
    required this.threshold,
    required this.participantCount,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final AppLocalizations loc;
  final int threshold;
  final int participantCount;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.medium,
      children: [
        if (isMobileDevice || context.isCompactLayout)
          _ThresholdPicker(
            loc: loc,
            threshold: threshold,
            participantCount: participantCount,
            enabled: enabled,
            onChanged: onChanged,
          )
        else
          _ThresholdSelect(
            loc: loc,
            threshold: threshold,
            participantCount: participantCount,
            enabled: enabled,
            onChanged: onChanged,
          ),
        _ThresholdSummary(
          loc: loc,
          threshold: threshold,
          participantCount: participantCount,
        ),
      ],
    );
  }
}

class _ThresholdPicker extends StatelessWidget {
  const _ThresholdPicker({
    required this.loc,
    required this.threshold,
    required this.participantCount,
    required this.enabled,
    required this.onChanged,
  });

  final AppLocalizations loc;
  final int threshold;
  final int participantCount;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final duration = _thresholdMotionDuration(context);

    return Semantics(
      label: loc.threshold,
      enabled: enabled,
      value: threshold.toString(),
      child: IgnorePointer(
        ignoring: !enabled,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.5,
          duration: duration,
          child: SizedBox(
            height: 132,
            child: FPicker(
              control: .lifted(
                indexes: [threshold - 1],
                duration: duration,
                curve: Curves.easeInOutCubic,
                onChange: (indexes) {
                  if (indexes.isNotEmpty) onChanged(indexes.first + 1);
                },
              ),
              children: [
                FPickerWheel(
                  semanticsLabel: loc.threshold,
                  semanticsValueBuilder: (index) => '${index + 1}',
                  children: [
                    for (var value = 1; value <= participantCount; value++)
                      Center(child: Text('$value')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThresholdSelect extends StatelessWidget {
  const _ThresholdSelect({
    required this.loc,
    required this.threshold,
    required this.participantCount,
    required this.enabled,
    required this.onChanged,
  });

  final AppLocalizations loc;
  final int threshold;
  final int participantCount;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return FSelect<int>.rich(
      label: Text(loc.multisig_setup_threshold_label),
      enabled: enabled,
      control: .lifted(
        value: threshold,
        onChange: (value) {
          if (value != null) onChanged(value);
        },
      ),
      format: (value) => value.toString(),
      children: [
        for (var value = 1; value <= participantCount; value++)
          FSelectItem<int>(title: Text('$value'), value: value),
      ],
    );
  }
}

class _ThresholdSummary extends StatelessWidget {
  const _ThresholdSummary({
    required this.loc,
    required this.threshold,
    required this.participantCount,
  });

  final AppLocalizations loc;
  final int threshold;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spaces.smallMedium),
      decoration: BoxDecoration(
        color: context.theme.colors.primary.withValues(alpha: 0.08),
        borderRadius: context.theme.style.borderRadius.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            FLucideIcons.keyRound,
            size: 18,
            color: context.theme.colors.primary,
          ),
          const SizedBox(width: Spaces.small),
          Expanded(
            child: Text(
              loc.multisig_setup_threshold_summary(threshold, participantCount),
              style: context.theme.typography.body.sm,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThreshold extends StatelessWidget {
  const _EmptyThreshold({required this.loc, super.key});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
      child: Text(
        loc.multisig_setup_threshold_empty,
        textAlign: TextAlign.center,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }
}
