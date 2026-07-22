import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

class MultisigSetupComplete extends StatelessWidget {
  const MultisigSetupComplete({
    required this.loc,
    required this.onFinish,
    super.key,
  });

  final AppLocalizations loc;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spaces.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spaces.large,
              children: [
                _BroadcastIllustration(),
                Column(
                  spacing: Spaces.small,
                  children: [
                    Text(
                      loc.multisig_setup_broadcast_title,
                      textAlign: TextAlign.center,
                      style: context.theme.typography.display.xl,
                    ),
                    Text(
                      loc.multisig_setup_broadcast_description,
                      textAlign: TextAlign.center,
                      style: context.theme.typography.body.md.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                FButton(
                  onPress: onFinish,
                  prefix: const Icon(FLucideIcons.arrowRight, size: 18),
                  child: Text(loc.multisig_setup_finish),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BroadcastIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: context.theme.colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          FLucideIcons.send,
          size: 40,
          color: context.theme.colors.primary,
        ),
      ),
    );
  }
}
