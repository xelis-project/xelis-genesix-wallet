import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/asset_name_widget.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class InvokeContractEntryContent extends ConsumerStatefulWidget {
  const InvokeContractEntryContent(this.invokeContractEntry, {super.key});

  final InvokeContractEntry invokeContractEntry;

  @override
  ConsumerState<InvokeContractEntryContent> createState() =>
      _InvokeContractEntryContentState();
}

class _InvokeContractEntryContentState
    extends ConsumerState<InvokeContractEntryContent> {
  final Map<String, AssetData> _fetchedAssets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMissingAssetMetadata();
  }

  Future<void> _fetchMissingAssetMetadata() async {
    final knownAssets = ref.read(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final repository = ref.read(walletStateProvider).nativeWalletRepository;

    if (repository == null) {
      setState(() => _isLoading = false);
      return;
    }

    for (final assetHash in widget.invokeContractEntry.deposits.keys) {
      if (!knownAssets.containsKey(assetHash)) {
        try {
          final assetData = await repository.getAssetMetadata(assetHash);
          _fetchedAssets[assetHash] = assetData;
        } catch (e) {
          // If fetch fails, leave it as unknown
        }
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );
    final knownAssets = ref.watch(
      walletStateProvider.select((state) => state.knownAssets),
    );

    // Merge known assets with fetched assets
    final allAssets = {...knownAssets, ..._fetchedAssets};

    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            LabeledValue.text(
              loc.contract,
              widget.invokeContractEntry.contract,
            ),
            LabeledValue.text(
              loc.fee,
              formatXelis(widget.invokeContractEntry.fee, network),
            ),
            LabeledValue.text(
              loc.entry_id,
              widget.invokeContractEntry.entryId.toString(),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    loc.deposits,
                    style: context.theme.typography.base.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  FItemGroup.builder(
                    count: widget.invokeContractEntry.deposits.length,
                    itemBuilder: (context, index) {
                      final deposit = widget
                          .invokeContractEntry
                          .deposits
                          .entries
                          .elementAt(index);

                      final formattedData = getFormattedAssetNameAndAmount(
                        allAssets,
                        deposit.key,
                        deposit.value,
                      );
                      final assetName = formattedData.$1;
                      final amount = formattedData.$2;

                      return FItem(
                        title: AssetNameWidget(
                          assetName: assetName,
                          isXelis: isXelis(deposit.key),
                        ),
                        details: SelectableText(amount),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
