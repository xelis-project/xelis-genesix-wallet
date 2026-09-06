import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class ReceiveAddressDialog extends ConsumerStatefulWidget {
  const ReceiveAddressDialog(this.animation, {super.key});

  final Animation<double> animation;

  @override
  ConsumerState<ReceiveAddressDialog> createState() =>
      _ReceiveAddressDialogState();
}

class _ReceiveAddressDialogState extends ConsumerState<ReceiveAddressDialog> {
  String _attachedDataDraft = '';
  String? _attachedData;
  XelisAddressDescriptor? _integratedAddress;
  String? _integratedAddressError;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletAddress = ref.watch(
      walletRuntimeProvider.select((state) => state.address),
    );
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );

    final isWideLayout = context.isWideLayout;
    final maxDialogWidth = context.responsiveDialogMaxWidth(medium: 600);
    final maxBodyHeight = context.responsiveDialogMaxHeight();
    final dialogWidth = context.responsiveDialogWidth(medium: 600);
    final qrSize = math
        .min(dialogWidth - (Spaces.medium * 4), maxBodyHeight * 0.5)
        .clamp(168.0, 280.0)
        .toDouble();
    final isDarkTheme =
        context.theme.colors.background.computeLuminance() < 0.5;
    final qrForegroundColor = isDarkTheme
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111111);
    final activeIntegratedAddress =
        _integratedAddress?.baseAddress == walletAddress
        ? _integratedAddress
        : null;
    final displayedAddress =
        activeIntegratedAddress?.encodedAddress ?? walletAddress;
    final isIntegrated = activeIntegratedAddress != null;

    return AppDialog(
      clipBehavior: Clip.antiAlias,
      animation: widget.animation,
      constraints: BoxConstraints(minWidth: 280, maxWidth: maxDialogWidth),
      body: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBodyHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(Spaces.extraSmall),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        loc.receive,
                        style: context.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ),
                    FButton.icon(
                      variant: .ghost,
                      semanticsLabel: loc.close,
                      semanticsTooltip: loc.close,
                      onPress: () => context.pop(),
                      child: const Icon(FLucideIcons.x, size: 22),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spaces.extraSmall),
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.colors.secondaryForeground.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: context.theme.style.borderRadius.md,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spaces.small,
                      vertical: Spaces.extraSmall,
                    ),
                    child: Text(
                      translateNetworkName(loc, network),
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.theme.colors.secondaryForeground.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: context.theme.style.borderRadius.md,
                  border: Border.all(color: context.theme.colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spaces.small),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Spaces.small,
                    children: [
                      Text(
                        isIntegrated
                            ? loc.integrated_address_detected
                            : loc.wallet_address_capitalize,
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      SelectableText(
                        displayedAddress,
                        maxLines: isWideLayout && !isIntegrated ? 1 : null,
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.foreground,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FButton(
                          variant: .outline,
                          prefix: const Icon(FLucideIcons.copy, size: 16),
                          onPress: displayedAddress.isEmpty
                              ? null
                              : () => copyToClipboard(
                                  displayedAddress,
                                  ref,
                                  loc.copied_to_clipboard,
                                ),
                          child: Text(loc.copy),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              Padding(
                padding: const EdgeInsets.all(Spaces.small),
                child: Center(
                  child: SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: PrettyQrView.data(
                      data: displayedAddress,
                      decoration: PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(color: qrForegroundColor),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              FAccordion(
                children: [
                  FAccordionItem(
                    title: Text(loc.receive_advanced_payment_request),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: Spaces.medium,
                      children: [
                        Text(
                          loc.receive_advanced_payment_request_description,
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        FTextField.multiline(
                          control: .managed(onChange: _onAttachedDataChanged),
                          label: Text(loc.receive_attached_text_label),
                          hint: loc.receive_attached_text_hint,
                          error: _integratedAddressError == null
                              ? null
                              : Text(_integratedAddressError!),
                          minLines: 2,
                          maxLines: 4,
                          autocorrect: false,
                          enableSuggestions: false,
                          clearable: (value) => value.text.isNotEmpty,
                        ),
                        FButton(
                          onPress:
                              walletAddress.isEmpty ||
                                  _attachedDataDraft.trim().isEmpty
                              ? null
                              : () => _createIntegratedAddress(walletAddress),
                          prefix: const Icon(FLucideIcons.qrCode, size: 16),
                          child: Text(loc.receive_create_integrated_address),
                        ),
                        if (isIntegrated && _attachedData != null)
                          _IntegratedAddressPreview(
                            attachedData: _attachedData!,
                            description: loc
                                .receive_integrated_address_data_visible_description,
                            title: loc.receive_integrated_address_data_visible,
                            valueLabel: loc.receive_attached_text_label,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }

  void _onAttachedDataChanged(TextEditingValue value) {
    if (value.text == _attachedDataDraft) return;

    setState(() {
      _attachedDataDraft = value.text;
      _attachedData = null;
      _integratedAddress = null;
      _integratedAddressError = null;
    });
  }

  void _createIntegratedAddress(String walletAddress) {
    final attachedData = _attachedDataDraft;
    if (attachedData.trim().isEmpty) return;

    try {
      final descriptor = XelisWalletFlutter.makeIntegratedAddress(
        baseAddress: walletAddress,
        integratedData: XelisDataElement.value(
          XelisDataValue.string(attachedData),
        ),
      );

      setState(() {
        _attachedData = attachedData;
        _integratedAddress = descriptor;
        _integratedAddressError = null;
      });
    } on XelisWalletException catch (error, stackTrace) {
      if (error.code == XelisWalletErrorCode.invalidInput) {
        setState(() {
          _attachedData = null;
          _integratedAddress = null;
          _integratedAddressError = ref
              .read(appLocalizationsProvider)
              .receive_integrated_address_invalid_data;
        });
        return;
      }

      _reportIntegratedAddressFailure(error, stackTrace);
    } catch (error, stackTrace) {
      _reportIntegratedAddressFailure(error, stackTrace);
    }
  }

  void _reportIntegratedAddressFailure(Object error, StackTrace stackTrace) {
    final failure = recordAppFailure(
      error,
      stackTrace,
      operation: 'wallet.receive.integrated_address.create',
      applicationCode: 'wallet_receive_integrated_address_create_failed',
    );
    final loc = ref.read(appLocalizationsProvider);

    setState(() {
      _attachedData = null;
      _integratedAddress = null;
      _integratedAddressError = loc.receive_integrated_address_invalid_data;
    });
    ref.read(toastProvider.notifier).showFailure(failure: failure);
  }
}

class _IntegratedAddressPreview extends StatelessWidget {
  const _IntegratedAddressPreview({
    required this.attachedData,
    required this.description,
    required this.title,
    required this.valueLabel,
  });

  final String attachedData;
  final String description;
  final String title;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return FAlert(
      icon: const Icon(FLucideIcons.eye, size: 18),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: Spaces.extraSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.small,
          children: [
            Text(description),
            Text(
              valueLabel,
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            SelectableText(
              attachedData,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
