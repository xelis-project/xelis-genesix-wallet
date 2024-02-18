import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/node_tab/node_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/settings_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/assets_tab/assets_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/history_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/wallet_tab_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/hub_app_bar_widget.dart';

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  int _currentPageIndex = 2; // Default wallet tab

  Widget _getScaffoldBodyShape(BuildContext context, Widget child) {
    return SafeArea(
        child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxHeight: context.mediaSize.height),
                child: child)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Scaffold(
      appBar: const HubAppBar(),
      body: <Widget>[
        _getScaffoldBodyShape(context, const NodeTab()),
        _getScaffoldBodyShape(context, const HistoryTab()),
        _getScaffoldBodyShape(context, const WalletTab()),
        _getScaffoldBodyShape(context, const AssetsTab()),
        _getScaffoldBodyShape(context, const SettingsTab()),
      ][_currentPageIndex],
      bottomNavigationBar: NavigationBar(
        animationDuration: Duration.zero,
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        selectedIndex: _currentPageIndex,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            label: loc.node_bottom_app_bar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.manage_search_outlined),
            label: loc.history_bottom_app_bar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: loc.wallet_bottom_app_bar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assessment_outlined),
            label: loc.assets_bottom_app_bar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: loc.settings_bottom_app_bar,
          ),
        ],
      ),
    );
  }
}
