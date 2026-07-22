import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';

enum _SignatureRevealDirection { fromTop, fromEnd }

class AnimatedSignatureList extends StatelessWidget {
  const AnimatedSignatureList({
    required this.listKey,
    required this.shares,
    required this.participants,
    required this.canRemove,
    required this.onRemove,
    super.key,
  });

  final GlobalKey<AnimatedListState> listKey;
  final List<MultisigSignatureShare> shares;
  final Map<int, ParticipantDartPayload> participants;
  final bool canRemove;
  final ValueChanged<MultisigSignatureShare> onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedList.separated(
      key: listKey,
      initialItemCount: shares.length,
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      itemBuilder: (context, index, animation) {
        final share = shares[index];
        return AnimatedVerifiedParticipant(
          key: ValueKey(share.signerId),
          animation: animation,
          signerId: share.signerId,
          participant: participants[share.signerId],
          onRemove: canRemove ? () => onRemove(share) : null,
        );
      },
      separatorBuilder: (context, index, animation) =>
          _AnimatedSignatureSeparator(animation: animation),
      removedSeparatorBuilder: (context, index, animation) =>
          _AnimatedSignatureSeparator(animation: animation),
    );
  }
}

class _AnimatedSignatureSeparator extends StatelessWidget {
  const _AnimatedSignatureSeparator({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );

    return SizeTransition(
      sizeFactor: curved,
      alignment: AlignmentDirectional.topStart,
      child: const SizedBox(height: Spaces.medium),
    );
  }
}

class AnimatedVerifiedParticipant extends StatelessWidget {
  const AnimatedVerifiedParticipant({
    required this.animation,
    required this.signerId,
    required this.participant,
    required this.onRemove,
    super.key,
  });

  final Animation<double> animation;
  final int signerId;
  final ParticipantDartPayload? participant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _SignatureRevealTransition(
      animation: animation,
      direction: _SignatureRevealDirection.fromEnd,
      child: _VerifiedParticipant(
        signerId: signerId,
        participant: participant,
        onRemove: onRemove,
      ),
    );
  }
}

class AnimatedSignatureEntryState extends StatelessWidget {
  const AnimatedSignatureEntryState({
    required this.isInputVisible,
    required this.controller,
    required this.error,
    required this.isInputEnabled,
    required this.duration,
    required this.maxLength,
    required this.onChanged,
    required this.onPaste,
    super.key,
  });

  final bool isInputVisible;
  final TextEditingController controller;
  final String? error;
  final bool isInputEnabled;
  final Duration duration;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        transitionBuilder: (child, animation) => _SignatureRevealTransition(
          animation: animation,
          direction: _SignatureRevealDirection.fromTop,
          child: child,
        ),
        child: isInputVisible
            ? _SignatureShareInput(
                key: const ValueKey('signature-input'),
                controller: controller,
                error: error,
                isEnabled: isInputEnabled,
                maxLength: maxLength,
                onChanged: onChanged,
                onPaste: onPaste,
              )
            : const SizedBox.shrink(key: ValueKey('signature-empty')),
      ),
    );
  }
}

class _SignatureRevealTransition extends StatelessWidget {
  const _SignatureRevealTransition({
    required this.animation,
    required this.direction,
    required this.child,
  });

  final Animation<double> animation;
  final _SignatureRevealDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final begin = switch (direction) {
      _SignatureRevealDirection.fromTop => const Offset(0, -28),
      _SignatureRevealDirection.fromEnd => Offset(
        Directionality.of(context) == TextDirection.ltr ? 32 : -32,
        0,
      ),
    };

    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        alignment: AlignmentDirectional.topStart,
        child: AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => Transform.translate(
            offset: Offset.lerp(begin, Offset.zero, curved.value)!,
            child: child,
          ),
        ),
      ),
    );
  }
}

class SigningRequestCard extends ConsumerWidget {
  const SigningRequestCard({required this.request, super.key});

  final MultisigSigningRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.medium,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  FLucideIcons.send,
                  size: 32,
                  color: context.theme.colors.primary,
                ),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spaces.extraSmall,
                    children: [
                      Text(
                        loc.copy_multisig_signing_request,
                        style: context.theme.typography.display.lg,
                      ),
                      Text(
                        loc.multisig_share_request_instruction,
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            FButton(
              onPress: () => copyToClipboard(request.encoded, ref, loc.copied),
              prefix: const Icon(FLucideIcons.copy, size: 18),
              child: Text(loc.copy_multisig_signing_request),
            ),
            FAccordion(
              children: [
                FAccordionItem(
                  style: const FAccordionStyleDelta.delta(
                    dividerStyle: FDividerStyleDelta.delta(
                      color: Colors.transparent,
                      padding: EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
                    ),
                  ),
                  title: Text(loc.more_details),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Spaces.medium,
                    children: [
                      LabeledValue.text(loc.wallet, request.source),
                      LabeledValue.text(loc.network, request.network),
                      LabeledValue.text(loc.hash, request.hash),
                      LabeledValue.text(
                        loc.threshold,
                        '${request.threshold}/${request.participants.length}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignatureShareInput extends ConsumerWidget {
  const _SignatureShareInput({
    required this.controller,
    required this.error,
    required this.isEnabled,
    required this.maxLength,
    required this.onChanged,
    required this.onPaste,
    super.key,
  });

  final TextEditingController controller;
  final String? error;
  final bool isEnabled;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: loc.signature_share,
          textField: true,
          child: FTextField(
            enabled: isEnabled,
            control: .managed(
              controller: controller,
              onChange: (value) => onChanged(value.text),
            ),
            autocorrect: false,
            keyboardType: TextInputType.multiline,
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            minLines: 3,
            maxLines: 3,
            hint: loc.paste_signature_share,
            error: error == null ? null : Text(error!),
          ),
        ),
        const SizedBox(height: Spaces.small),
        Align(
          alignment: Alignment.centerRight,
          child: FButton(
            variant: .ghost,
            onPress: isEnabled ? onPaste : null,
            prefix: const Icon(FLucideIcons.clipboardPaste, size: 18),
            child: Text(loc.paste_signature_share),
          ),
        ),
      ],
    );
  }
}

class _VerifiedParticipant extends ConsumerWidget {
  const _VerifiedParticipant({
    required this.signerId,
    required this.participant,
    required this.onRemove,
  });

  final int signerId;
  final ParticipantDartPayload? participant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          FLucideIcons.circleCheckBig,
          size: 16,
          color: context.theme.colors.primary,
        ),
        const SizedBox(width: Spaces.extraSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spaces.extraSmall,
            children: [
              Text('${loc.participant_id} #${signerId + 1}'),
              if (participant != null) AddressWidget(participant!.address),
            ],
          ),
        ),
        FButton.icon(
          variant: .destructive,
          onPress: onRemove,
          semanticsLabel: loc.remove_signature_share,
          child: const Icon(FLucideIcons.trash2, size: 18),
        ),
      ],
    );
  }
}
