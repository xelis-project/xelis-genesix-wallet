import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:go_router/go_router.dart';

class SetupMultisig extends ConsumerStatefulWidget {
  const SetupMultisig({super.key});

  @override
  ConsumerState<SetupMultisig> createState() => _SetupMultisigState();
}

class _SetupMultisigState extends ConsumerState<SetupMultisig> {
  final _formKey = GlobalKey<FormState>();
  final _thresholdController = TextEditingController(text: '1');
  final List<TextEditingController> _participantControllers = [
    TextEditingController(),
  ];

  TransactionSummary? _transaction;
  bool _confirmed = false;
  bool _isPreparing = false;
  bool _isBroadcasting = false;
  bool _isComplete = false;

  @override
  void dispose() {
    _thresholdController.dispose();
    for (final controller in _participantControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final title = _transaction == null
        ? loc.multisig_setup_title
        : _isComplete
        ? loc.multisig
        : loc.review;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isPreparing && !_isBroadcasting) {
          _handleBack();
        }
      },
      child: FScaffold(
        header: FHeader.nested(
          title: Text(title),
          prefixes: [
            Padding(
              padding: const EdgeInsets.all(Spaces.small),
              child: FHeaderAction.back(
                onPress: _isPreparing || _isBroadcasting ? null : _handleBack,
              ),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spaces.medium),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: AppDurations.animFast),
                  child: _isComplete
                      ? _buildComplete(context)
                      : _transaction == null
                      ? _buildConfiguration(context)
                      : _buildReview(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguration(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('multisig-configuration'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.large,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spaces.small,
            children: [
              Text(
                loc.multisig_setup_title,
                style: context.theme.typography.display.xl2,
              ),
              Text(
                '${loc.multisig_setup_message_1}\n'
                '${loc.multisig_setup_message_2}\n'
                '${loc.multisig_setup_message_3}',
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
          FAlert(
            title: Text(loc.warning),
            subtitle: Text(loc.multisig_setup_confirmation_message),
          ),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.medium,
                children: [
                  Text(
                    loc.threshold,
                    style: context.theme.typography.display.lg,
                  ),
                  FTextFormField(
                    control: .managed(controller: _thresholdController),
                    keyboardType: TextInputType.number,
                    label: Text(loc.threshold_formfield_label_text),
                    validator: _validateThreshold,
                  ),
                ],
              ),
            ),
          ),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: Spaces.medium,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          loc.participants,
                          style: context.theme.typography.display.lg,
                        ),
                      ),
                      FButton.icon(
                        variant: .outline,
                        onPress: _participantControllers.length >= 255
                            ? null
                            : _addParticipant,
                        semanticsLabel: loc.participants,
                        child: const Icon(FLucideIcons.plus, size: 18),
                      ),
                    ],
                  ),
                  ..._participantControllers.indexed.map(
                    (entry) => _ParticipantField(
                      key: ValueKey(entry.$2),
                      index: entry.$1,
                      controller: entry.$2,
                      canRemove: _participantControllers.length > 1,
                      validator: (value) =>
                          _validateParticipant(value, entry.$1),
                      onRemove: () => _removeParticipant(entry.$1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AsyncFButton(
              isLoading: _isPreparing,
              onPress: _isPreparing ? null : _prepare,
              prefix: const Icon(FLucideIcons.arrowRight, size: 18),
              child: Text(loc.next),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final transaction = _transaction!;

    return Column(
      key: const ValueKey('multisig-review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.small,
          children: [
            Text(loc.review, style: context.theme.typography.display.xl2),
            Text(
              loc.multisig_setup_confirmation_message,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(Spaces.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spaces.medium,
              children: [
                _ReviewRow(label: loc.hash, value: transaction.hash),
                const FDivider(),
                _ReviewRow(
                  label: loc.fee,
                  value: formatXelis(transaction.fee, network),
                ),
                _ReviewRow(
                  label: loc.threshold,
                  value: _thresholdController.text.trim(),
                ),
              ],
            ),
          ),
        ),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(Spaces.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spaces.medium,
              children: [
                Text(
                  loc.participants,
                  style: context.theme.typography.display.lg,
                ),
                ..._participantControllers.indexed.map(
                  (entry) => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FBadge(
                        variant: .outline,
                        child: Text('#${entry.$1 + 1}'),
                      ),
                      const SizedBox(width: Spaces.medium),
                      Expanded(child: AddressWidget(entry.$2.text.trim())),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        FCheckbox(
          value: _confirmed,
          onChange: (value) => setState(() => _confirmed = value),
          label: Text(loc.multisig_setup_confirmation_message),
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: [
            FButton(
              variant: .outline,
              onPress: _isBroadcasting ? null : _editConfiguration,
              child: Text(loc.edit_button),
            ),
            AsyncFButton(
              isLoading: _isBroadcasting,
              onPress: !_confirmed || _isBroadcasting
                  ? null
                  : () => startWithBiometricAuth(
                      ref,
                      callback: _broadcast,
                      reason: loc.please_authenticate_tx,
                    ),
              prefix: const Icon(FLucideIcons.send, size: 18),
              child: Text(loc.broadcast),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplete(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      key: const ValueKey('multisig-complete'),
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: Spaces.large,
      children: [
        Icon(
          FLucideIcons.circleCheckBig,
          size: 72,
          color: context.theme.colors.primary,
        ),
        Text(
          loc.transaction_broadcast_message,
          textAlign: TextAlign.center,
          style: context.theme.typography.display.xl,
        ),
        FButton(
          onPress: () => context.go(AuthAppScreen.multisig.toPath),
          child: Text(loc.close),
        ),
      ],
    );
  }

  String? _validateThreshold(String? value) {
    final loc = ref.read(appLocalizationsProvider);
    final threshold = int.tryParse(value?.trim() ?? '');
    if (threshold == null) return loc.must_be_numeric_error;
    if (threshold < 1 ||
        threshold > 255 ||
        threshold > _participantControllers.length) {
      return loc.threshold_formfield_error;
    }
    return null;
  }

  String? _validateParticipant(String? value, int index) {
    final loc = ref.read(appLocalizationsProvider);
    final address = value?.trim() ?? '';
    if (address.isEmpty) return loc.field_required_error;
    if (!ref.read(walletCommandsProvider).isAddressValidForMultisig(address)) {
      return loc.multisig_address_validation_error;
    }
    final duplicate = _participantControllers.indexed.any(
      (entry) => entry.$1 != index && entry.$2.text.trim() == address,
    );
    return duplicate ? loc.multisig_participant_duplicated : null;
  }

  void _addParticipant() {
    setState(() => _participantControllers.add(TextEditingController()));
  }

  void _removeParticipant(int index) {
    setState(() => _participantControllers.removeAt(index).dispose());
  }

  Future<void> _prepare() async {
    if (_isPreparing || !(_formKey.currentState?.validate() ?? false)) return;
    final commands = ref.read(walletCommandsProvider);
    setState(() => _isPreparing = true);
    try {
      final transaction = await commands.setupMultisig(
        participants: _participantControllers
            .map((controller) => controller.text.trim())
            .toList(growable: false),
        threshold: int.parse(_thresholdController.text.trim()),
      );
      if (transaction == null) return;
      if (!mounted) {
        await commands.cancelTransaction(hash: transaction.hash);
        return;
      }
      setState(() => _transaction = transaction);
    } finally {
      if (mounted) setState(() => _isPreparing = false);
    }
  }

  Future<void> _broadcast(WidgetRef ref) async {
    if (_isBroadcasting) return;
    setState(() => _isBroadcasting = true);
    try {
      final broadcasted = await ref
          .read(walletCommandsProvider)
          .broadcastTx(hash: _transaction!.hash);
      if (!mounted || !broadcasted) return;
      ref.read(multisigPendingStateProvider.notifier).pendingState();
      ref
          .read(toastProvider.notifier)
          .showEvent(
            description: ref
                .read(appLocalizationsProvider)
                .transaction_broadcast_message,
          );
      setState(() => _isComplete = true);
    } on AnyhowException {
      talker.error('Cannot broadcast multisig setup transaction');
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .showError(description: ref.read(appLocalizationsProvider).oups);
      }
    } catch (_) {
      talker.error('Cannot broadcast multisig setup transaction');
      if (mounted) {
        ref
            .read(toastProvider.notifier)
            .showError(description: ref.read(appLocalizationsProvider).oups);
      }
    } finally {
      if (mounted) setState(() => _isBroadcasting = false);
    }
  }

  Future<void> _editConfiguration() async {
    final transaction = _transaction;
    if (transaction != null) {
      await ref
          .read(walletCommandsProvider)
          .cancelTransaction(hash: transaction.hash);
    }
    if (!mounted) return;
    setState(() {
      _transaction = null;
      _confirmed = false;
    });
  }

  Future<void> _handleBack() async {
    if (_transaction != null && !_isComplete) {
      await _editConfiguration();
      return;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AuthAppScreen.multisig.toPath);
    }
  }
}

class _ParticipantField extends ConsumerWidget {
  const _ParticipantField({
    super.key,
    required this.index,
    required this.controller,
    required this.canRemove,
    required this.validator,
    required this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final bool canRemove;
  final FormFieldValidator<String> validator;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: Spaces.small),
          child: FBadge(variant: .outline, child: Text('#${index + 1}')),
        ),
        const SizedBox(width: Spaces.small),
        Expanded(
          child: FTextFormField(
            control: .managed(controller: controller),
            autocorrect: false,
            label: Text(loc.wallet_address_capitalize),
            clearable: (value) => value.text.isNotEmpty,
            validator: validator,
          ),
        ),
        const SizedBox(width: Spaces.small),
        FButton.icon(
          variant: .ghost,
          onPress: canRemove ? onRemove : null,
          semanticsLabel: loc.delete_multisig_configuration,
          child: const Icon(FLucideIcons.trash2, size: 18),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.extraSmall,
      children: [
        Text(
          label,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        SelectableText(value),
      ],
    );
  }
}
