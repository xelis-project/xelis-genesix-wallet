import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/presentation/components/logger_selector_widget.dart';
import 'package:genesix/features/settings/presentation/components/reset_preference_button.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/presentation/components/layout_widget.dart';
import 'package:genesix/features/settings/presentation/components/theme_selector_widget.dart';
import 'package:genesix/features/settings/presentation/components/language_selector_widget.dart';
import 'package:genesix/features/settings/presentation/components/network_selector_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';

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
  void initState() {
    super.initState();

    getAppCacheDirPath().then((path) {
      setState(() {
        _cachePath = path;
      });
    });

    getAppWalletsDirPath().then((path) {
      setState(() {
        _walletsPath = path;
      });
    });

    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        _version = packageInfo.version;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.app_settings),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spaces.large,
          Spaces.none,
          Spaces.large,
          Spaces.large,
        ),
        children: [
          const NetworkSelectorWidget(),
          const Divider(),
          const ThemeSelectorWidget(),
          const Divider(),
          const LanguageSelectorWidget(),
          const Divider(),
          const LoggerSelectorWidget(),
          const Divider(),
          HorizontalContainer(title: loc.version, value: _version),
          const Divider(),
          VerticalContainer(title: loc.wallets_directory, value: _walletsPath),
          const Divider(),
          VerticalContainer(title: loc.cache_directory, value: _cachePath),
          const Divider(),
          const SizedBox(height: Spaces.medium),
          Row(
            children: [
              if (context.isWideScreen) Spacer(),
              Expanded(flex: 2, child: ResetPreferenceButton()),
              if (context.isWideScreen) Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}
