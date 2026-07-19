import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';

const _maxMultisigSigningRequestLength = 3 * 1024 * 1024;

class SignTransactionContent extends ConsumerStatefulWidget {
  const SignTransactionContent({super.key});

  @override
  ConsumerState createState() => _SignTransactionContentState();
}

class _SignTransactionContentState
    extends ConsumerState<SignTransactionContent> {
  final _formKey = GlobalKey<FormState>();
  final _requestController = TextEditingController();

  MultisigSigningRequest? _request;
  MultisigSignatureShare? _signatureShare;
  var _submitted = false;
  var _isInspecting = false;
  var _isSigning = false;

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final runtime = ref.watch(walletRuntimeProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spaces.medium),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: Column(
              spacing: Spaces.large,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FTextFormField(
                  enabled: !_isInspecting && !_isSigning && _request == null,
                  control: .managed(
                    controller: _requestController,
                    onChange: (_) => _resetResult(),
                  ),
                  autovalidateMode: _submitted
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  label: Text(loc.multisig_signing_request),
                  hint: loc.enter_multisig_signing_request,
                  keyboardType: TextInputType.multiline,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      _maxMultisigSigningRequestLength,
                    ),
                  ],
                  minLines: 4,
                  maxLines: 8,
                  clearable: (value) => value.text.isNotEmpty,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.field_required_error;
                    }
                    return null;
                  },
                ),
                if (_request == null)
                  AsyncFButton(
                    isLoading: _isInspecting,
                    onPress: _inspectRequest,
                    prefix: const Icon(FLucideIcons.shieldCheck, size: 18),
                    child: Text(loc.continue_button),
                  )
                else ...[
                  _SigningRequestPreview(request: _request!, runtime: runtime),
                  if (_signatureShare == null) ...[
                    if (_request!.signerId == null)
                      FAlert(
                        title: Text(loc.not_available),
                        subtitle: Text(loc.wallet_not_multisig_participant),
                      ),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: Spaces.small,
                      runSpacing: Spaces.small,
                      children: [
                        FButton(
                          variant: .outline,
                          onPress: _isSigning ? null : _clearRequest,
                          child: Text(loc.cancel_button),
                        ),
                        AsyncFButton(
                          isLoading: _isSigning,
                          onPress: _request!.signerId == null
                              ? null
                              : () => startWithBiometricAuth(
                                  ref,
                                  callback: (_) => _signRequest(),
                                  reason: loc.please_authenticate_tx,
                                ),
                          prefix: const Icon(FLucideIcons.penLine, size: 18),
                          child: Text(loc.sign_transaction),
                        ),
                      ],
                    ),
                  ] else
                    _SignatureShareCard(
                      share: _signatureShare!,
                      onCopy: () => copyToClipboard(
                        _signatureShare!.encoded,
                        ref,
                        loc.copied,
                      ),
                      onDone: _clearRequest,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetResult() {
    if (_submitted || _request != null || _signatureShare != null) {
      setState(() {
        _submitted = false;
        _request = null;
        _signatureShare = null;
      });
    }
  }

  void _clearRequest() {
    setState(() {
      _submitted = false;
      _request = null;
      _signatureShare = null;
      _requestController.clear();
    });
  }

  Future<void> _inspectRequest() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isInspecting = true);
    try {
      final request = await ref
          .read(walletCommandsProvider)
          .inspectMultisigSigningRequest(_requestController.text.trim());
      if (!mounted || request == null) {
        return;
      }
      setState(() {
        _request = request;
        _signatureShare = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isInspecting = false);
      }
    }
  }

  Future<void> _signRequest() async {
    final request = _request;
    if (request == null || _isSigning) {
      return;
    }

    setState(() => _isSigning = true);
    try {
      final share = await ref
          .read(walletCommandsProvider)
          .signMultisigSigningRequest(request.encoded);
      if (!mounted || share == null || share.requestHash != request.hash) {
        return;
      }
      setState(() => _signatureShare = share);
    } finally {
      if (mounted) {
        setState(() => _isSigning = false);
      }
    }
  }
}

class _SigningRequestPreview extends ConsumerWidget {
  const _SigningRequestPreview({required this.request, required this.runtime});

  final MultisigSigningRequest request;
  final WalletRuntimeState runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final transactionDetails = switch (request.transaction) {
      MultisigSigningTransaction_Transfers(:final transfers) => Column(
        spacing: Spaces.small,
        children: [
          for (final transfer in transfers)
            _TransferPreview(transfer: transfer, runtime: runtime),
        ],
      ),
      MultisigSigningTransaction_Burn(:final asset, :final amount) => Column(
        children: [
          _DetailRow(
            label: runtime.knownAssets.containsKey(asset)
                ? loc.amount
                : loc.raw_amount,
            value: _formatAmount(amount, asset),
          ),
          _DetailRow(label: loc.asset, value: asset),
        ],
      ),
      MultisigSigningTransaction_DeleteMultisig() => _DetailRow(
        label: loc.multisig,
        value: loc.delete_multisig_configuration,
      ),
    };

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          spacing: Spaces.small,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  FLucideIcons.badgeCheck,
                  color: context.theme.colors.primary,
                ),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: Text(
                    loc.multisig_signing_request,
                    style: context.theme.typography.display.lg,
                  ),
                ),
              ],
            ),
            const FDivider(),
            _DetailRow(label: loc.wallet, value: request.source),
            _DetailRow(label: loc.network, value: request.network),
            _DetailRow(label: loc.transaction_id, value: request.hash),
            _DetailRow(
              label: loc.fee,
              value: formatXelis(request.fee, runtime.network),
            ),
            _DetailRow(
              label: loc.fee_limit,
              value: formatXelis(request.feeLimit, runtime.network),
            ),
            _DetailRow(
              label: loc.threshold,
              value: '${request.threshold}/${request.participants.length}',
            ),
            _DetailRow(
              label: loc.participant_id,
              value: request.signerId == null
                  ? '—'
                  : '#${request.signerId! + 1}',
            ),
            _DetailRow(
              label: loc.topoheight,
              value: request.referenceTopoheight.toString(),
            ),
            const FDivider(),
            transactionDetails,
          ],
        ),
      ),
    );
  }

  String _formatAmount(BigInt amount, String asset) {
    final metadata = runtime.knownAssets[asset];
    if (metadata == null) return amount.toString();
    return formatCoin(amount, metadata.decimals, metadata.ticker);
  }
}

class _TransferPreview extends ConsumerWidget {
  const _TransferPreview({required this.transfer, required this.runtime});

  final MultisigSigningTransfer transfer;
  final WalletRuntimeState runtime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final metadata = runtime.knownAssets[transfer.asset];
    final amount = metadata == null
        ? transfer.amount.toString()
        : formatCoin(transfer.amount, metadata.decimals, metadata.ticker);

    return Column(
      children: [
        _DetailRow(
          label: metadata == null ? loc.raw_amount : loc.amount,
          value: amount,
        ),
        _DetailRow(label: loc.destination, value: transfer.destination),
        _DetailRow(label: loc.asset, value: transfer.asset),
        if (transfer.hasExtraData)
          _DetailRow(label: loc.extra_data, value: loc.enabled),
      ],
    );
  }
}

class _SignatureShareCard extends ConsumerWidget {
  const _SignatureShareCard({
    required this.share,
    required this.onCopy,
    required this.onDone,
  });

  final MultisigSignatureShare share;
  final VoidCallback onCopy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          spacing: Spaces.medium,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.signature_share,
              style: context.theme.typography.display.lg,
            ),
            SelectableText(share.encoded),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: Spaces.small,
              runSpacing: Spaces.small,
              children: [
                FButton(
                  variant: .outline,
                  onPress: onDone,
                  child: Text(loc.close),
                ),
                FButton(
                  onPress: onCopy,
                  prefix: const Icon(FLucideIcons.copy, size: 18),
                  child: Text(loc.copy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: context.theme.typography.body.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ),
        const SizedBox(width: Spaces.small),
        Expanded(child: SelectableText(value)),
      ],
    );
  }
}
