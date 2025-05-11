import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/presentation/assets_navigation_bar/tracked_balances_tab.dart';

import 'discovered_assets_tab.dart';

class AssetsNavigationBar extends ConsumerWidget {
  const AssetsNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Tracked Balances'),
              Tab(text: 'Discovered Assets'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [TrackedBalancesTab(), DiscoveredAssetsTab()],
            ),
          ),
        ],
      ),
    );
  }
}
