import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/more_colors.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';

class SigningRequestReview extends ConsumerWidget {
  const SigningRequestReview({
    required this.request,
    required this.runtime,
    required this.participant,
    required this.isNodeAvailable,
    required this.nodeRequirementMessage,
    required this.deleteConfirmed,
    required this.isSigning,
    required this.signingFailed,
    required this.onDeleteConfirmationChanged,
    required this.onEdit,
    required this.onSign,
    super.key,
  });

  final MultisigSigningRequest request;
  final WalletRuntimeState runtime;
  final ParticipantDartPayload? participant;
  final bool isNodeAvailable;
  final String nodeRequirementMessage;
  final bool deleteConfirmed;
  final bool isSigning;
  final bool signingFailed;
  final ValueChanged<bool> onDeleteConfirmationChanged;
  final VoidCallback onEdit;
  final VoidCallback onSign;

  bool get _isDelete =>
      request.transaction is MultisigSigningTransaction_DeleteMultisig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final canSign =
        participant != null &&
        isNodeAvailable &&
        (!_isDelete || deleteConfirmed) &&
        !isSigning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        _ReviewHeader(loc: loc),
        if (!isNodeAvailable)
          FAlert(
            title: Text(loc.node_required),
            subtitle: Text(nodeRequirementMessage),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final useHorizontalLayout =
                constraints.maxWidth >= context.theme.breakpoints.md;
            final operation = _OperationCard(
              request: request,
              runtime: runtime,
              loc: loc,
            );
            final signer = participant == null
                ? _BlockedSignerPanel(loc: loc)
                : _VerifiedSignerPanel(
                    loc: loc,
                    participant: participant!,
                    runtime: runtime,
                  );

            if (!useHorizontalLayout) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.large,
                children: [signer, operation],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: operation),
                const SizedBox(width: Spaces.large),
                Expanded(flex: 2, child: signer),
              ],
            );
          },
        ),
        _RequestDetailsCard(request: request, runtime: runtime, loc: loc),
        if (_isDelete)
          _DeleteConfirmation(
            loc: loc,
            value: deleteConfirmed,
            enabled: !isSigning,
            onChanged: onDeleteConfirmationChanged,
          ),
        if (signingFailed)
          _StatusPanel(
            icon: FLucideIcons.circleAlert,
            accent: context.theme.colors.destructive,
            title: loc.not_available,
            description: loc.multisig_signing_failed,
          ),
        _ReviewActions(
          loc: loc,
          isSigning: isSigning,
          canSign: canSign,
          expand: context.isCompactLayout,
          onEdit: onEdit,
          onSign: onSign,
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
          loc.multisig_signing_review_title,
          style: context.theme.typography.display.xl2,
        ),
        Text(
          loc.multisig_signing_review_description,
          style: context.theme.typography.body.md.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

class _VerifiedSignerPanel extends StatelessWidget {
  const _VerifiedSignerPanel({
    required this.loc,
    required this.participant,
    required this.runtime,
  });

  final AppLocalizations loc;
  final ParticipantDartPayload participant;
  final WalletRuntimeState runtime;

  @override
  Widget build(BuildContext context) {
    return _StatusPanel(
      icon: FLucideIcons.badgeCheck,
      accent: context.theme.colors.primary,
      title: loc.verified_multisig_request,
      child: LabeledValue.child(
        loc.multisig_signing_wallet_label,
        _CurrentSignerIdentity(
          name: runtime.name,
          address: participant.address,
          participantId: participant.id + 1,
          loc: loc,
        ),
      ),
    );
  }
}

class _CurrentSignerIdentity extends StatelessWidget {
  const _CurrentSignerIdentity({
    required this.name,
    required this.address,
    required this.participantId,
    required this.loc,
  });

  final String name;
  final String address;
  final int participantId;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HashiconWidget(hash: address, size: const Size.square(32)),
        const SizedBox(width: Spaces.smallMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spaces.extraSmall,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                loc.multisig_signing_current_wallet_participant(participantId),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              SelectableText(address, style: context.theme.typography.body.sm),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlockedSignerPanel extends StatelessWidget {
  const _BlockedSignerPanel({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return _StatusPanel(
      icon: FLucideIcons.triangleAlert,
      accent: context.theme.colors.warningColor,
      title: loc.not_available,
      description: loc.wallet_not_multisig_participant,
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.accent,
    required this.title,
    this.description,
    this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        borderRadius: context.theme.style.borderRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.smallMedium,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 24,
                child: Center(child: Icon(icon, size: 20, color: accent)),
              ),
              const SizedBox(width: Spaces.small),
              Expanded(
                child: Text(
                  title,
                  style: context.theme.typography.body.md.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (description case final description?)
            Text(
              description,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.request,
    required this.runtime,
    required this.loc,
  });

  final MultisigSigningRequest request;
  final WalletRuntimeState runtime;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final (icon, accent, title, details) = switch (request.transaction) {
      MultisigSigningTransaction_Transfers(:final transfers) => (
        FLucideIcons.send,
        context.theme.colors.primary,
        loc.transfer,
        _TransferDetails(transfers: transfers, runtime: runtime, loc: loc),
      ),
      MultisigSigningTransaction_Burn(:final asset, :final amount) => (
        FLucideIcons.flame,
        context.theme.colors.primary,
        loc.burn,
        _BurnDetails(asset: asset, amount: amount, runtime: runtime, loc: loc),
      ),
      MultisigSigningTransaction_DeleteMultisig() => (
        FLucideIcons.trash2,
        context.theme.colors.warningColor,
        loc.multisig_removal,
        null,
      ),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.large,
        children: [
          LabeledValue.child(
            loc.transaction_type,
            Row(
              children: [
                Icon(icon, size: 20, color: accent),
                const SizedBox(width: Spaces.small),
                Expanded(child: Text(title)),
              ],
            ),
          ),
          ?details,
        ],
      ),
    );
  }
}

class _TransferDetails extends StatelessWidget {
  const _TransferDetails({
    required this.transfers,
    required this.runtime,
    required this.loc,
  });

  final List<MultisigSigningTransfer> transfers;
  final WalletRuntimeState runtime;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, transfer) in transfers.indexed) ...[
          if (transfers.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: Spaces.small),
              child: FBadge(
                variant: .outline,
                child: Text('${loc.transfer} #${index + 1}'),
              ),
            ),
          LabeledValue.text(
            runtime.knownAssets.containsKey(transfer.asset)
                ? loc.amount
                : loc.raw_amount,
            _formatAmount(transfer.amount, transfer.asset, runtime),
          ),
          const SizedBox(height: Spaces.smallMedium),
          LabeledValue.child(
            loc.destination,
            AddressWidget(
              transfer.destination,
              compact: context.isCompactLayout,
            ),
          ),
          const SizedBox(height: Spaces.smallMedium),
          LabeledValue.text(loc.asset, transfer.asset),
          if (transfer.hasExtraData) ...[
            const SizedBox(height: Spaces.smallMedium),
            LabeledValue.text(loc.extra_data, loc.enabled),
          ],
          if (index != transfers.length - 1) ...[
            const SizedBox(height: Spaces.medium),
            const FDivider(),
            const SizedBox(height: Spaces.medium),
          ],
        ],
      ],
    );
  }
}

class _BurnDetails extends StatelessWidget {
  const _BurnDetails({
    required this.asset,
    required this.amount,
    required this.runtime,
    required this.loc,
  });

  final String asset;
  final BigInt amount;
  final WalletRuntimeState runtime;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.smallMedium,
      children: [
        LabeledValue.text(
          runtime.knownAssets.containsKey(asset) ? loc.amount : loc.raw_amount,
          _formatAmount(amount, asset, runtime),
        ),
        LabeledValue.text(loc.asset, asset),
      ],
    );
  }
}

class _RequestDetailsCard extends StatelessWidget {
  const _RequestDetailsCard({
    required this.request,
    required this.runtime,
    required this.loc,
  });

  final MultisigSigningRequest request;
  final WalletRuntimeState runtime;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.large,
        children: [
          Text(
            loc.multisig_request_details_title,
            style: context.theme.typography.display.md,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < context.theme.breakpoints.sm;
              final itemWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - Spaces.large) / 2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.medium,
                children: [
                  Wrap(
                    spacing: Spaces.large,
                    runSpacing: Spaces.medium,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: LabeledValue.text(
                          loc.fee,
                          formatXelis(request.fee, runtime.network),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: LabeledValue.text(
                          loc.fee_limit,
                          formatXelis(request.feeLimit, runtime.network),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: LabeledValue.text(loc.network, request.network),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: LabeledValue.text(
                          loc.threshold,
                          '${request.threshold}/${request.participants.length}',
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: LabeledValue.text(
                          loc.topoheight,
                          request.referenceTopoheight.toString(),
                        ),
                      ),
                    ],
                  ),
                  const FDivider(),
                  LabeledValue.child(
                    loc.multisig_source_wallet_label,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: Spaces.small,
                      children: [
                        AddressWidget(
                          request.source,
                          compact: context.isCompactLayout,
                        ),
                        Text(
                          loc.multisig_source_wallet_description,
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LabeledValue.text(loc.transaction_id, request.hash),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmation extends StatelessWidget {
  const _DeleteConfirmation({
    required this.loc,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final AppLocalizations loc;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.medium,
      children: [
        _StatusPanel(
          icon: FLucideIcons.triangleAlert,
          accent: context.theme.colors.warningColor,
          title: loc.warning,
          description: loc.multisig_signing_delete_warning,
        ),
        FCheckbox(
          value: value,
          enabled: enabled,
          onChange: enabled ? onChanged : null,
          label: Text(loc.multisig_signing_delete_confirmation),
        ),
      ],
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.loc,
    required this.isSigning,
    required this.canSign,
    required this.expand,
    required this.onEdit,
    required this.onSign,
  });

  final AppLocalizations loc;
  final bool isSigning;
  final bool canSign;
  final bool expand;
  final VoidCallback onEdit;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) {
    final edit = FButton(
      variant: .outline,
      onPress: isSigning ? null : onEdit,
      child: Text(loc.edit_button),
    );
    final sign = AsyncFButton(
      isLoading: isSigning,
      onPress: canSign ? onSign : null,
      prefix: const Icon(FLucideIcons.penLine, size: 18),
      child: Text(loc.sign_multisig_request_action),
    );

    if (expand) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.small,
        children: [edit, sign],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      children: [edit, sign],
    );
  }
}

String _formatAmount(BigInt amount, String asset, WalletRuntimeState runtime) {
  final metadata = runtime.knownAssets[asset];
  if (metadata == null) return amount.toString();
  return formatCoin(amount, metadata.decimals, metadata.ticker);
}
