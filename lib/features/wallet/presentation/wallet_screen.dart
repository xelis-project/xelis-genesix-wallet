import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/history_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/node_tab/node_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/assets_tab/assets_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/settings_tab/settings_tab_widget.dart';
import 'package:genesix/features/wallet/presentation/wallet_tab/wallet_tab_widget.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';

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
    final isHandset =
        context.formFactor == ScreenSize.normal ||
        context.formFactor == ScreenSize.small;

    final tabs =
        <Widget>[
          const NodeTab(),
          const HistoryTab(),
          const WalletTab(),
          const AssetsTab(),
          SettingsTab(),
        ][_currentPageIndex];

    final List<BottomNavigationBarItem> bottomNavigationBarItems = [
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
    ];

    // Export CSV button for HistoryTab
    Widget floatingExportCSVButton = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          onPressed: () => _exportCsv(),
          tooltip: loc.export_csv_tooltip,
          child: const Icon(Icons.download_rounded),
        ),
      ],
    );

    Widget mainWidget;

    if (isHandset) {
      mainWidget = CustomScaffold(
        backgroundColor: Colors.transparent,
        body: tabs,
        bottomNavigationBar: BottomNavigationBar(
          onTap: (int index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
          currentIndex: _currentPageIndex,
          items: bottomNavigationBarItems,
        ),
        // if HistoryTab, show export button
        floatingActionButton:
            _currentPageIndex == 1 ? floatingExportCSVButton : null,
      );
    } else if (context.isWideScreen) {
      mainWidget = CustomScaffold(
        backgroundColor: Colors.transparent,
        body: tabs,
        bottomNavigationBar: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Spaces.extraLarge),
            topRight: Radius.circular(Spaces.extraLarge),
          ),
          child: BottomNavigationBar(
            onTap: (int index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            currentIndex: _currentPageIndex,
            items: bottomNavigationBarItems,
          ),
        ),
        // if HistoryTab, show export button
        floatingActionButton:
            _currentPageIndex == 1 ? floatingExportCSVButton : null,
      );
    } else {
      mainWidget = Row(
        children: [
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: context.theme.copyWith(
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: Colors.transparent,
              ),
            ),
            home: NavigationRail(
              selectedIndex: _currentPageIndex,
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
          ),
          Expanded(
            child: CustomScaffold(
              backgroundColor: Colors.transparent,
              body: tabs,
              // if HistoryTab, show export button
              floatingActionButton:
                  _currentPageIndex == 1 ? floatingExportCSVButton : null,
            ),
          ),
        ],
      );
    }

    return mainWidget;
  }

  Future<void> _exportCsv() async {
    final loc = ref.read(appLocalizationsProvider);

    try {
      final count = await ref.read(historyCountProvider.future);
      if (count != null && count == 0) {
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.no_transactions_to_export);
        return;
      }
    } catch (e) {
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError(loc.error_exporting_csv);
      return;
    }

    if (kIsWeb) {
      try {
        final content =
            await ref.read(walletStateProvider.notifier).exportCsvForWeb();
        if (content != null) {
          saveTextFile(content, 'genesix_transactions.csv');
          ref
              .read(snackBarMessengerProvider.notifier)
              .showInfo(loc.csv_exported_successfully);
        } else {
          throw Exception();
        }
      } catch (e) {
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.error_exporting_csv);
      }
    } else {
      var path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        try {
          await ref.read(walletStateProvider.notifier).exportCsv(path);
          ref
              .read(snackBarMessengerProvider.notifier)
              .showInfo(loc.csv_exported_successfully);
        } catch (e) {
          if (e.toString().contains(loc.no_transactions_to_export)) {
            ref
                .read(snackBarMessengerProvider.notifier)
                .showError(loc.no_transactions_to_export);
          } else {
            ref
                .read(snackBarMessengerProvider.notifier)
                .showError(loc.error_exporting_csv);
          }
        }
      }
    }
  }
}
