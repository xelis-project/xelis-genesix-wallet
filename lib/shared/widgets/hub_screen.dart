import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/widgets/brightness_toggle.dart';
import 'package:xelis_mobile_wallet/shared/widgets/popup_menu.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Xelis Wallet'),
        title: AppResources.logoXelisHorizontal,
        automaticallyImplyLeading: false,
        actions: const [
          BrightnessToggle(),
          PopupMenu(),
        ],
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, child) {
          final loc = ref.watch(appLocalizationsProvider);
          return NavigationBar(
            onDestinationSelected: (int index) {
              setState(() {
                currentPageIndex = index;
              });
            },
            selectedIndex: currentPageIndex,
            destinations: <Widget>[
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                label: loc.explore_bottom_app_bar,
              ),
              NavigationDestination(
                icon: const Icon(Icons.manage_search_outlined),
                label: loc.history_bottom_app_bar,
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: loc.assets_bottom_app_bar,
              ),
            ],
          );
        },
      ),
      body: <Widget>[
        Container(
          color: Colors.red,
          alignment: Alignment.center,
          child: const Text('Page 1'),
        ),
        Container(
          color: Colors.green,
          alignment: Alignment.center,
          child: const Text('Page 2'),
        ),
        Container(
          color: Colors.blue,
          alignment: Alignment.center,
          child: const Text('Page 3'),
        ),
      ][currentPageIndex],
    );
  }
}
