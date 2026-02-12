import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
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
        LabeledValue.text(loc.fee, formatXelis(multisigEntry.fee, network)),
        LabeledValue.text(loc.status, loc.multisig_deleted),
      ];
    } else {
      content = [
        LabeledValue.text(loc.fee, formatXelis(multisigEntry.fee, network)),
        LabeledValue.text(loc.threshold, multisigEntry.threshold.toString()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              loc.participants,
              style: context.theme.typography.base.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            FItemGroup.builder(
              itemBuilder: (context, index) {
                final participant = multisigEntry.participants[index];
                return FItem(title: AddressWidget(participant));
              },
            ),
          ],
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.medium,
      children: content,
    );
  }
}
