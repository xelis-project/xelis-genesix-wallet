import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class SignatureShareReady extends ConsumerWidget {
  const SignatureShareReady({
    required this.share,
    required this.participant,
    required this.copied,
    required this.onCopy,
    required this.onRestart,
    super.key,
  });

  final XelisWalletMultisigSignatureShare share;
  final XelisWalletMultisigParticipant? participant;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AppCard(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spaces.large,
              children: [
                _SuccessIllustration(),
                Column(
                  spacing: Spaces.small,
                  children: [
                    Text(
                      loc.multisig_signature_ready_title,
                      textAlign: TextAlign.center,
                      style: context.theme.typography.display.xl,
                    ),
                    Text(
                      loc.multisig_signature_ready_description,
                      textAlign: TextAlign.center,
                      style: context.theme.typography.body.md.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                _SignerIdentity(
                  signerId: share.participantId,
                  participant: participant,
                  loc: loc,
                ),
                _SignatureValue(value: share.encoded),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Spaces.small,
                  children: [
                    FButton(
                      onPress: onCopy,
                      prefix: Icon(
                        copied
                            ? FLucideIcons.circleCheckBig
                            : FLucideIcons.copy,
                        size: 18,
                      ),
                      child: Text(
                        copied ? loc.copied : loc.copy_multisig_signature_share,
                      ),
                    ),
                    FButton(
                      variant: .outline,
                      onPress: onRestart,
                      child: Text(loc.sign_another_multisig_request),
                    ),
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

class _SuccessIllustration extends StatelessWidget {
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
          FLucideIcons.circleCheckBig,
          size: 40,
          color: context.theme.colors.primary,
        ),
      ),
    );
  }
}

class _SignerIdentity extends StatelessWidget {
  const _SignerIdentity({
    required this.signerId,
    required this.participant,
    required this.loc,
  });

  final int signerId;
  final XelisWalletMultisigParticipant? participant;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.theme.colors.primary.withValues(alpha: 0.08),
        borderRadius: context.theme.style.borderRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.small,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FBadge(
              variant: .outline,
              child: Text('${loc.participant_id} #${signerId + 1}'),
            ),
          ),
          if (participant != null) AddressWidget(participant!.address),
        ],
      ),
    );
  }
}

class _SignatureValue extends StatelessWidget {
  const _SignatureValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(Spaces.smallMedium),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        border: Border.all(color: context.theme.colors.border),
        borderRadius: context.theme.style.borderRadius.md,
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          value,
          style: context.theme.typography.body.xs.copyWith(
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
