import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:forui/forui.dart';

class DeployContractBuilderWidget extends ConsumerStatefulWidget {
  final DeployContractBuilder deployContractBuilder;

  const DeployContractBuilderWidget({
    super.key,
    required this.deployContractBuilder,
  });

  @override
  ConsumerState<DeployContractBuilderWidget> createState() =>
      _DeployContractBuilderWidgetState();
}

class _DeployContractBuilderWidgetState
    extends ConsumerState<DeployContractBuilderWidget>
    with TransactionBuilderMixin {
  bool _showContract = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final contract = widget.deployContractBuilder.contract.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.deploy_contract,
              style: context.bodyLarge!.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        buildLabeledText(context, loc.bytes, '${contract.length ~/ 2}'),
        FButton(
          key: const ValueKey('xswd-contract-module-details'),
          onPress: () => setState(() => _showContract = !_showContract),
          child: Text(loc.more_details),
        ),
        if (_showContract) ...[
          const SizedBox(height: Spaces.extraSmall),
          Text(
            loc.contract,
            style: context.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            contract,
            style: context.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ],
        const SizedBox(height: Spaces.small),
        if (widget.deployContractBuilder.invoke != null)
          InvokeWidget(
            maxGas: widget.deployContractBuilder.invoke!.maxGas,
            deposits: widget.deployContractBuilder.invoke!.deposits,
          ),
      ],
    );
  }
}
