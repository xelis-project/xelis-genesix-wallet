import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/languages_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/node_addresses_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/brightness_toggle.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_outlined),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8),
            child: BrightnessToggle(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Consumer(
                builder: (context, ref, child) {
                  final loc = ref.watch(appLocalizationsProvider);
                  return Text(
                    loc.settings,
                    style: context.headlineLarge,
                  );
                },
              ),
            ),
            const LanguageWidget(),
            const NodeAddressesWidget(),
          ],
        ),
      ),
    );
  }
}
