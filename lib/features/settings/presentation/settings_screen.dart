import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/layout_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/theme_selector_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/language_selector_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/network_selector_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _walletsPath = '';
  String _cachePath = '';
  String _version = '';

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    getAppCachePath().then((path) {
      setState(() {
        _cachePath = path;
      });
    });

    getAppWalletsPath().then((path) {
      setState(() {
        _walletsPath = path;
      });
    });

    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        _version = packageInfo.version;
      });
    });

    return Scaffold(
      body: Background(
        child: ListView(
          padding: const EdgeInsets.all(Spaces.large),
          children: [
            const BackHeader(
              title: 'App settings',
            ),
            const SizedBox(height: Spaces.large),
            const NetworkSelectorWidget(),
            const Divider(),
            const ThemeSelectorWidget(),
            const Divider(),
            const LanguageSelectorWidget(),
            const Divider(),
            HorizontalContainer(title: loc.version, value: _version),
            const Divider(),
            VerticalContainer(
                title: loc.wallets_directory, value: _walletsPath),
            const Divider(),
            VerticalContainer(title: loc.cache_directory, value: _cachePath)
          ],
        ),
      ),
    );
  }
}
