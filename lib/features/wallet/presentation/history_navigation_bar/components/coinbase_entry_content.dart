import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class CoinbaseEntryContent extends ConsumerWidget {
  const CoinbaseEntryContent(this.coinbaseEntry, {super.key});

  final CoinbaseEntry coinbaseEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletStateProvider.select((state) => state.network),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.amount,
          style: context.labelLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(
          '+${formatXelis(coinbaseEntry.reward, network)}',
          style: context.bodyLarge,
        ),
      ],
    );
  }
}
