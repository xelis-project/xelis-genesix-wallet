import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/assets_navigation_bar/components/tracked_balance_item.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class TrackedBalancesTab extends ConsumerWidget {
  const TrackedBalancesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final balances = ref.watch(
      walletStateProvider.select((state) => state.trackedBalances),
    );

    if (balances.isEmpty) {
      return Center(
        child: Text(
          loc.no_tracked_balances,
          style: context.bodyLarge?.copyWith(
            color: context.moreColors.mutedColor,
          ),
        ),
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: balances.length,
        padding: const EdgeInsets.all(Spaces.large),
        itemBuilder: (BuildContext context, int index) {
          final hash = balances.keys.toList()[index];
          return TrackedBalanceItem(assetHash: hash);
        },
      );
    }
  }
}
