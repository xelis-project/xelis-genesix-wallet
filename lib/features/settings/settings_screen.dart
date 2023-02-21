import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_app/shared/theme/extensions.dart';
import 'package:xelis_wallet_app/shared/views/brightness_toggle.dart';

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
        actions: const [BrightnessToggle()],
      ),
      body: Center(
        child: Text(
          'SETTINGS',
          style: context.bodyLarge,
        ),
      ),
    );
  }
}
