import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/daemon_addresses_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/language_widget.dart';
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
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Settings',
                  style: context.headlineLarge,
                ),
              ),
              const LanguageWidget(),
              const DaemonAddressesWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
