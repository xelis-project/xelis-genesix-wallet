import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

class MultisigIntroduction extends StatelessWidget {
  const MultisigIntroduction({
    required this.loc,
    required this.onConfigure,
    super.key,
  });

  final AppLocalizations loc;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontalLayout =
            constraints.maxWidth >= context.theme.breakpoints.md &&
            context.viewportHeight >= 620;
        final maxWidth = useHorizontalLayout ? 880.0 : 560.0;
        final content = useHorizontalLayout
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MultisigIllustration(size: 112, iconSize: 54),
                  const SizedBox(width: Spaces.extraLarge),
                  Expanded(
                    child: _MultisigIntroductionDetails(
                      loc: loc,
                      onConfigure: onConfigure,
                      expandButton: false,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.large,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: _MultisigIllustration(size: 88, iconSize: 42),
                  ),
                  _MultisigIntroductionDetails(
                    loc: loc,
                    onConfigure: onConfigure,
                    expandButton: true,
                  ),
                ],
              );

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: useHorizontalLayout
                ? Spaces.extraLarge * 1.5
                : Spaces.medium,
            vertical: useHorizontalLayout ? Spaces.extraLarge : Spaces.medium,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: AppCard(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: EdgeInsets.all(
                    useHorizontalLayout ? Spaces.medium : 0,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MultisigIllustration extends StatelessWidget {
  const _MultisigIllustration({required this.size, required this.iconSize});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        FLucideIcons.shieldCheck,
        size: iconSize,
        color: colors.primary,
      ),
    );
  }
}

class _MultisigIntroductionDetails extends StatelessWidget {
  const _MultisigIntroductionDetails({
    required this.loc,
    required this.onConfigure,
    required this.expandButton,
  });

  final AppLocalizations loc;
  final VoidCallback onConfigure;
  final bool expandButton;

  @override
  Widget build(BuildContext context) {
    final button = FButton(
      onPress: onConfigure,
      prefix: const Icon(FLucideIcons.arrowRight, size: 18),
      child: Text(loc.configure_multisig),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.smallMedium,
          children: [
            Text(
              loc.multisig_intro_title,
              style: context.theme.typography.display.lg,
            ),
            Text(
              loc.multisig_intro_description,
              style: context.theme.typography.body.md.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        _MultisigIntroductionSteps(loc: loc),
        FAlert(
          title: Text(loc.warning),
          subtitle: Text(loc.multisig_intro_warning),
        ),
        if (expandButton)
          SizedBox(width: double.infinity, child: button)
        else
          Align(alignment: Alignment.centerLeft, child: button),
      ],
    );
  }
}

class _MultisigIntroductionSteps extends StatelessWidget {
  const _MultisigIntroductionSteps({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MultisigIntroductionStep(
          icon: FLucideIcons.users,
          title: loc.multisig_intro_participants_title,
          description: loc.multisig_intro_participants_description,
        ),
        const _MultisigStepDivider(),
        _MultisigIntroductionStep(
          icon: FLucideIcons.lock,
          title: loc.multisig_intro_threshold_title,
          description: loc.multisig_intro_threshold_description,
        ),
        const _MultisigStepDivider(),
        _MultisigIntroductionStep(
          icon: FLucideIcons.badgeCheck,
          title: loc.multisig_intro_review_title,
          description: loc.multisig_intro_review_description,
        ),
      ],
    );
  }
}

class _MultisigStepDivider extends StatelessWidget {
  const _MultisigStepDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.only(left: 48), child: FDivider());
  }
}

class _MultisigIntroductionStep extends StatelessWidget {
  const _MultisigIntroductionStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.smallMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Spaces.small),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: Spaces.smallMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Spaces.extraSmall,
              children: [
                Text(
                  title,
                  style: context.theme.typography.body.sm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
