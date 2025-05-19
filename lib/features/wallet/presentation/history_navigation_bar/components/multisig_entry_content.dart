import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class MultisigEntryContent extends ConsumerWidget {
  const MultisigEntryContent(this.multisigEntry, {super.key});

  final MultisigEntry multisigEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );

    List<Widget> content;
    if (multisigEntry.participants.isEmpty) {
      content = [
        Text(
          loc.fee,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(
          formatXelis(multisigEntry.fee, network),
          style: context.bodyLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.status,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(loc.multisig_deleted, style: context.bodyLarge),
      ];
    } else {
      content = [
        Text(
          loc.fee,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(
          formatXelis(multisigEntry.fee, network),
          style: context.bodyLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.threshold,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(
          multisigEntry.threshold.toString(),
          style: context.bodyLarge,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.participants,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        Builder(
          builder: (BuildContext context) {
            var participants = multisigEntry.participants;

            return ListView.builder(
              shrinkWrap: true,
              itemCount: participants.length,
              itemBuilder: (BuildContext context, int index) {
                final participant = participants[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Spaces.medium),
                    child: AddressWidget(participant),
                  ),
                );
              },
            );
          },
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }
}
