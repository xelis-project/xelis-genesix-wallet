import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class CoinbaseEntryContent extends ConsumerWidget {
  const CoinbaseEntryContent(this.coinbaseEntry, {super.key});

  final CoinbaseEntry coinbaseEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: LabeledValue.text(
          loc.amount,
          '+${formatXelis(coinbaseEntry.reward, network)}',
        ),
      ),
    );
  }
}
