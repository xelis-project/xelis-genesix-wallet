import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/assets_tab/assets_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/explore_tab/explore_tab_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/history_tab_widget.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
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
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          title: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final userThemeMode = ref.watch(userThemeModeProvider);
              switch (userThemeMode.themeMode) {
                case ThemeMode.system:
                  if (context.isDarkMode) {
                    return AppResources.svgIconWhiteWidget;
                  } else {
                    return AppResources.svgIconGreenWidget;
                  }
                case ThemeMode.light:
                  return AppResources.svgIconGreenWidget;
                case ThemeMode.dark:
                  return AppResources.svgIconWhiteWidget;
              }
            },
          ),
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
          const Explore(),
          const History(),
          const Assets(),
        ][currentPageIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            logger.info('send button pressed');
          },
          child: const Icon(Icons.send),
        ),
      ),
    );
  }
}
