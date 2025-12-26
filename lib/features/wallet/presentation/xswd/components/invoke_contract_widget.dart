import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:forui/forui.dart';

class InvokeContractBuilderWidget extends ConsumerStatefulWidget {
  final InvokeContractBuilder invokeContractBuilder;

  const InvokeContractBuilderWidget({
    super.key,
    required this.invokeContractBuilder,
  });

  @override
  ConsumerState<InvokeContractBuilderWidget> createState() =>
      _InvokeContractBuilderWidgetState();
}

class _InvokeContractBuilderWidgetState
    extends ConsumerState<InvokeContractBuilderWidget>
    with TransactionBuilderMixin {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.invoke_contract,
              style: context.bodyLarge!.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spaces.medium),
        buildLabeledText(
          context,
          loc.contract,
          widget.invokeContractBuilder.contract,
        ),
        InvokeWidget(
          maxGas: widget.invokeContractBuilder.maxGas,
          entryId: widget.invokeContractBuilder.entryId,
          deposits: widget.invokeContractBuilder.deposits,
          parameters: widget.invokeContractBuilder.parameters,
        ),
      ],
    );
  }
}
