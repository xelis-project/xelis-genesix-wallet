import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/layout_widget.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/theme_selector_widget.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/language_selector_widget.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/network_selector_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var walletsPath = "";
  var cachePath = "";

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    getAppCachePath().then((path) {
      setState(() {
        cachePath = path;
      });
    });

    getAppWalletsPath().then((path) {
      setState(() {
        walletsPath = path;
      });
    });

    return Scaffold(
      body: Background(
        child: ListView(
          padding: const EdgeInsets.all(Spaces.large),
          children: [
            BackHeader(title: loc.settings),
            const SizedBox(height: Spaces.large),
            const NetworkSelectorWidget(),
            const Divider(),
            const ThemeSelectorWidget(),
            const Divider(),
            const LanguageSelectorWidget(),
            const Divider(),
            HorizontalContainer(title: loc.version, value: "0.1.0"),
            const Divider(),
            VerticalContainer(title: loc.wallets_directory, value: walletsPath),
            const Divider(),
            VerticalContainer(title: loc.cache_directory, value: cachePath)
          ],
        ),
      ),
    );
  }
}
