import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/node_tab/node_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/settings_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/assets_tab/assets_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/history_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/wallet_tab_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/hub_app_bar_widget.dart';

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  int _currentPageIndex = 2; // Default wallet tab

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final isHandset = context.formFactor == ScreenSize.normal ||
        context.formFactor == ScreenSize.small;

    final pages = SafeArea(
      child: <Widget>[
        const NodeTab(),
        const HistoryTab(),
        const WalletTab(),
        const AssetsTab(),
        const SettingsTab(),
      ][_currentPageIndex],
    );

    Widget mainWidget = isHandset
        ? Scaffold(
            appBar: const HubAppBar(),
            body: pages,
            bottomNavigationBar: isHandset
                ? NavigationBar(
                    animationDuration: Duration.zero,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    selectedIndex: _currentPageIndex,
                    destinations: <Widget>[
                      NavigationDestination(
                        icon: const Icon(Icons.explore_rounded),
                        label: loc.node_bottom_app_bar,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.manage_search_rounded),
                        label: loc.history_bottom_app_bar,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.account_balance_wallet_rounded),
                        label: loc.wallet_bottom_app_bar,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.assessment_rounded),
                        label: loc.assets_bottom_app_bar,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.settings_rounded),
                        label: loc.settings_bottom_app_bar,
                      ),
                    ],
                  )
                : null,
          )
        : Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentPageIndex,
                  groupAlignment: -1.0,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _currentPageIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  trailing: const SizedBox(),
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
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Scaffold(
                    appBar: const HubAppBar(),
                    body: pages,
                    bottomNavigationBar: isHandset
                        ? NavigationBar(
                            animationDuration: Duration.zero,
                            onDestinationSelected: (int index) {
                              setState(() {
                                _currentPageIndex = index;
                              });
                            },
                            selectedIndex: _currentPageIndex,
                            destinations: <Widget>[
                              NavigationDestination(
                                icon: const Icon(Icons.explore_rounded),
                                label: loc.node_bottom_app_bar,
                              ),
                              NavigationDestination(
                                icon: const Icon(Icons.manage_search_rounded),
                                label: loc.history_bottom_app_bar,
                              ),
                              NavigationDestination(
                                icon: const Icon(
                                    Icons.account_balance_wallet_rounded),
                                label: loc.wallet_bottom_app_bar,
                              ),
                              NavigationDestination(
                                icon: const Icon(Icons.assessment_rounded),
                                label: loc.assets_bottom_app_bar,
                              ),
                              NavigationDestination(
                                icon: const Icon(Icons.settings_rounded),
                                label: loc.settings_bottom_app_bar,
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ],
            ),
          );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: mainWidget,
    );
  }
}
