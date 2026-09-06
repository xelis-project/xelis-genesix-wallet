import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_value_presentation.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;
import 'package:forui/forui.dart';

class TransfersBuilderWidget extends ConsumerStatefulWidget {
  final TransfersBuilder transfersBuilder;
  final List<wallet_flutter.XelisAddressDescriptor> destinationDescriptors;

  const TransfersBuilderWidget({
    super.key,
    required this.transfersBuilder,
    required this.destinationDescriptors,
  });

  @override
  ConsumerState<TransfersBuilderWidget> createState() =>
      _TransfersBuilderWidgetState();
}

class _TransfersBuilderWidgetState extends ConsumerState<TransfersBuilderWidget>
    with TransactionBuilderMixin {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletRuntimeProvider.select((state) => state.knownAssets),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.transfers,
              style: context.bodyLarge!.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spaces.medium),
        _buildTransfersList(
          loc,
          widget.transfersBuilder.transfers,
          knownAssets,
          network,
        ),
      ],
    );
  }

  Widget _buildTransfersList(
    AppLocalizations loc,
    List<TransferBuilder> transfers,
    Map<String, wallet_flutter.XelisWalletAssetMetadata> knownAssets,
    wallet_flutter.XelisNetwork network,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: transfers.asMap().entries.map((entry) {
        final index = entry.key;
        final t = entry.value;
        final destination = _destinationDescriptor(index, t);
        String asset;
        String amount;
        if (t.asset == xelisAsset) {
          asset = '${AppResources.xelisName} (${t.asset})';
          amount = formatXelis(t.amount, network);
        } else if (knownAssets.containsKey(t.asset)) {
          final assetData = knownAssets[t.asset]!;
          asset = '${assetData.name} (${t.asset})';
          amount = formatCoin(t.amount, assetData.decimals, assetData.ticker);
        } else {
          asset = t.asset;
          amount = t.amount.toString();
        }

        final extraDataPreview = t.extraData == null
            ? null
            : xswdDataElementPreview(loc, t.extraData!);
        final integratedData = destination.integratedData;
        final integratedDataPreview = integratedData == null
            ? null
            : xswdIntegratedDataPreview(loc, integratedData);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spaces.small),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spaces.small),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLabeledText(context, loc.asset.toLowerCase(), asset),
              buildLabeledText(context, loc.amount.toLowerCase(), amount),
              Text(
                '${loc.destination.toLowerCase()}:',
                style: context.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              SelectableText(
                destination.baseAddress,
                key: ValueKey('xswd-transfer-destination-$index'),
                style: context.bodyMedium,
              ),
              if (integratedData != null) ...[
                const SizedBox(height: Spaces.extraSmall),
                Text(
                  loc.attached_data,
                  style: context.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                buildLabeledText(
                  context,
                  loc.attached_data_source,
                  loc.attached_data_source_integrated_address,
                ),
                buildLabeledText(
                  context,
                  loc.type,
                  integratedDataPreview!.type,
                ),
                SelectableText(
                  integratedDataPreview.text,
                  key: ValueKey('xswd-integrated-attached-data-preview-$index'),
                  style: context.bodySmall,
                ),
                const SizedBox(height: Spaces.extraSmall),
                _AttachedDataRevealButton(
                  key: ValueKey('xswd-integrated-attached-data-details-$index'),
                  label: loc.view_attached_data,
                  onPress: () => _showIntegratedAttachedDataDetails(
                    context,
                    loc,
                    index,
                    destination,
                  ),
                ),
              ],
              if (t.extraData != null) ...[
                const SizedBox(height: Spaces.extraSmall),
                Text(
                  loc.attached_data,
                  style: context.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                buildLabeledText(
                  context,
                  loc.attached_data_source,
                  loc.attached_data_source_explicit,
                ),
                SelectableText(
                  extraDataPreview!,
                  key: ValueKey('xswd-attached-data-preview-$index'),
                  style: context.bodySmall,
                ),
                const SizedBox(height: Spaces.extraSmall),
                _AttachedDataRevealButton(
                  key: ValueKey('xswd-attached-data-details-$index'),
                  label: loc.view_attached_data,
                  onPress: () => _showAttachedDataDetails(
                    context,
                    loc,
                    index,
                    t.extraData!,
                  ),
                ),
              ],
              if (integratedData != null || t.extraData != null) ...[
                buildLabeledText(
                  context,
                  loc.privacy,
                  t.encryptExtraData
                      ? loc.attached_data_encrypted
                      : loc.attached_data_not_encrypted,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  wallet_flutter.XelisAddressDescriptor _destinationDescriptor(
    int index,
    TransferBuilder transfer,
  ) {
    if (widget.destinationDescriptors.length !=
        widget.transfersBuilder.transfers.length) {
      throw StateError('Transfer destination review metadata is incomplete.');
    }
    final descriptor = widget.destinationDescriptors[index];
    if (descriptor.encodedAddress != transfer.destination) {
      throw StateError('Transfer destination review metadata does not match.');
    }
    return descriptor;
  }

  void _showAttachedDataDetails(
    BuildContext context,
    AppLocalizations loc,
    int index,
    DataElement extraData,
  ) {
    final fullValue = xswdFormatDataElement(extraData);
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => AppDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Text('${loc.attached_data} #${index + 1}'),
        body: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: XswdFullValueView(
            value: fullValue,
            key: ValueKey('xswd-attached-data-full-$index'),
            chunkKeyPrefix: 'xswd-attached-data-full-$index',
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }

  void _showIntegratedAttachedDataDetails(
    BuildContext context,
    AppLocalizations loc,
    int index,
    wallet_flutter.XelisAddressDescriptor destination,
  ) {
    final fullValue =
        '${loc.destination}:\n${destination.encodedAddress}\n\n'
        '${loc.attached_data}:\n'
        '${xswdFormatIntegratedData(destination.integratedData!)}';
    _showFullAttachedData(
      context,
      loc,
      index,
      fullValue,
      keyPrefix: 'xswd-integrated-attached-data-full',
    );
  }

  void _showFullAttachedData(
    BuildContext context,
    AppLocalizations loc,
    int index,
    String fullValue, {
    required String keyPrefix,
  }) {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => AppDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Text('${loc.attached_data} #${index + 1}'),
        body: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: XswdFullValueView(
            value: fullValue,
            key: ValueKey('$keyPrefix-$index'),
            chunkKeyPrefix: '$keyPrefix-$index',
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }
}

class _AttachedDataRevealButton extends StatelessWidget {
  const _AttachedDataRevealButton({
    required this.label,
    required this.onPress,
    super.key,
  });

  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return FTappable(
      semanticsTooltip: label,
      onPress: onPress,
      builder: (context, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              states.contains(FTappableVariant.hovered) ||
                  states.contains(FTappableVariant.pressed)
              ? context.theme.colors.secondary
              : Colors.transparent,
          border: Border.all(color: context.theme.colors.border),
          borderRadius: BorderRadius.circular(Spaces.small),
        ),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spaces.small,
          vertical: Spaces.extraSmall,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          softWrap: true,
          style: context.bodySmall,
        ),
      ),
    );
  }
}
