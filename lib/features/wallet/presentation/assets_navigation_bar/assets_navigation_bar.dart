import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/assets_navigation_bar/tracked_assets_tab.dart';

import 'untracked_assets_tab.dart';

class AssetsNavigationBar extends ConsumerWidget {
  const AssetsNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(tabs: [Tab(text: loc.tracked), Tab(text: loc.untracked)]),
          Expanded(
            child: TabBarView(
              children: [TrackedBalancesTab(), UntrackedAssetsTab()],
            ),
          ),
        ],
      ),
    );
  }
}
