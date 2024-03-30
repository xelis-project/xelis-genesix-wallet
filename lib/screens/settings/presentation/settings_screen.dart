import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/layout_widget.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/theme_switch_widget.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/languages_widget.dart';
import 'package:xelis_mobile_wallet/screens/settings/presentation/components/network_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:path/path.dart' as p;

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

    getApplicationCacheDirectory().then((dir) {
      setState(() {
        cachePath = dir.path;
      });
    });

    // TODO: get wallets path should be a global func
    getApplicationDocumentsDirectory().then((dir) {
      setState(() {
        walletsPath = p.join(dir.path, 'wallets');
      });
    });

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(Spaces.large),
        children: [
          Flex(
            direction: Axis.horizontal,
            children: [
              IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(
                  Icons.arrow_back,
                  size: 30,
                ),
              ),
              const SizedBox(width: Spaces.small),
              Text(
                loc.settings,
                style: context.headlineLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: Spaces.large),
          const ThemeSwitchWidget(),
          const Divider(),
          const LanguageWidget(),
          const Divider(),
          const NetworkWidget(),
          const Divider(),
          HorizontalContainer(title: loc.version, value: "0.1.0"),
          const Divider(),
          VerticalContainer(title: loc.wallets_directory, value: walletsPath),
          const Divider(),
          VerticalContainer(title: loc.cache_directory, value: cachePath)
        ],
      ),
    );
  }
}
