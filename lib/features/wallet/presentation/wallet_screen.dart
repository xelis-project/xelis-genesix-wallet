import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/node_tab/node_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/assets_tab/assets_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/history_tab/history_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/settings_tab/settings_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/wallet_tab_widget.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _currentPageIndex = 2; // Default wallet tab

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final isHandset = context.formFactor == ScreenSize.normal ||
        context.formFactor == ScreenSize.small;

    final tabs = <Widget>[
      const NodeTab(),
      const HistoryTab(),
      const WalletTab(),
      const AssetsTab(),
      const SettingsTab(),
    ][_currentPageIndex];

    Widget mainWidget;

    if (isHandset) {
      mainWidget = Scaffold(
        backgroundColor: Colors.transparent,
        //appBar: const HubAppBar(),
        body: tabs,
        bottomNavigationBar: BottomNavigationBar(
          //backgroundColor: Colors.black26,
          //labelBehavior:NavigationDestinationLabelBehavior.alwaysHide,
          //animationDuration: Duration.zero,
          /*indicatorShape: const CircleBorder(
                  side: BorderSide.none,
                ),*/

          onTap: (int index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          currentIndex: _currentPageIndex,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_rounded),
              label: loc.node_bottom_app_bar,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.manage_search_rounded),
              label: loc.history_bottom_app_bar,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: loc.wallet_bottom_app_bar,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assessment_rounded),
              label: loc.assets_bottom_app_bar,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              label: loc.settings_bottom_app_bar,
            ),
          ],
        ),
      );
    } else {
      mainWidget = Row(
        children: [
          NavigationRail(
            selectedIndex: _currentPageIndex,
            //groupAlignment: -1.0,
            onDestinationSelected: (int index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            //trailing: const SizedBox(),
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: const Icon(Icons.explore_rounded),
                label: Text(loc.node_bottom_app_bar),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.manage_search_rounded),
                label: Text(loc.history_bottom_app_bar),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.account_balance_wallet_rounded),
                label: Text(loc.wallet_bottom_app_bar),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.assessment_rounded),
                label: Text(loc.assets_bottom_app_bar),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_rounded),
                label: Text(loc.settings_bottom_app_bar),
              ),
            ],
          ),
          //const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              //appBar: const HubAppBar(),
              body: tabs,
            ),
          ),
        ],
      );
    }

    return Background(child: mainWidget);
  }
}
