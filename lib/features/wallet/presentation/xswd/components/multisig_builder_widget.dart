import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class MultisigBuilderWidget extends ConsumerStatefulWidget {
  final MultisigBuilder multisigBuilder;

  const MultisigBuilderWidget({super.key, required this.multisigBuilder});

  @override
  ConsumerState<MultisigBuilderWidget> createState() =>
      _MultisigBuilderWidgetState();
}

class _MultisigBuilderWidgetState extends ConsumerState<MultisigBuilderWidget>
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
              loc.multisig,
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
          ],
        ),
        buildLabeledText(
          context,
          loc.threshold,
          widget.multisigBuilder.threshold.toString(),
        ),
        Text(
          loc.participants,
          style: context.bodyMedium!.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        _buildParticipantsList(widget.multisigBuilder.participants),
      ],
    );
  }

  Widget _buildParticipantsList(List<String> participants) {
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
        children:
            participants.map((participant) {
              return AddressWidget(participant);
            }).toList(),
      ),
    );
  }
}
