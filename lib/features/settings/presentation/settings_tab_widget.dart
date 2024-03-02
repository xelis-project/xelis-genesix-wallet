import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/avatar_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/change_password_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/darkmode_switch_widget.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/languages_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final loc = ref.watch(appLocalizationsProvider);
              return Text(
                loc.settings,
                style: context.headlineLarge!
                    .copyWith(fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 24.0),
          const AvatarSelector(),
          const SizedBox(height: 24.0),
          const DarkModeSwitchWidget(),
          const LanguageWidget(),
          const ChangePasswordWidget()
        ],
      ),
    );
  }
}
