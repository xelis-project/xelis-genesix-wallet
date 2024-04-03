import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/router/route_utils.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/settings_tab/components/avatar_widget.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/settings_tab/components/change_password_widget.dart';
import 'package:xelis_mobile_wallet/screens/wallet/presentation/settings_tab/components/logout_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/password_dialog.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return ListView(
      padding: const EdgeInsets.all(Spaces.large),
      children: [
        Consumer(
          builder: (context, ref, child) {
            final loc = ref.watch(appLocalizationsProvider);
            return Text(
              loc.settings,
              style:
                  context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
            );
          },
        ),
        //const SizedBox(height: Spaces.large),
        //const AvatarSelector(),
        const SizedBox(height: Spaces.large),
        //const Divider(),
        ListTile(
          title: Text(
            'App Settings',
            style: context.titleLarge,
          ),
          onTap: () {
            context.push(AppScreen.settings.toPath);
          },
          trailing: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
        ),
        const Divider(),
        ListTile(
          title: Wrap(
            spacing: Spaces.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.pattern_rounded),
              Text(
                loc.my_seed,
                style: context.titleLarge,
              )
            ],
          ),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return PasswordDialog(
                  onValid: () {
                    context.push(AppScreen.walletSeed.toPath);
                  },
                );
              },
            );
          },
          trailing: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
        ),
        const Divider(),
        ListTile(
          title: Wrap(
            spacing: Spaces.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.password),
              Text(
                loc.change_password,
                style: context.titleLarge,
              )
            ],
          ),
          onTap: () {
            context.push(AppScreen.changePassword.toPath);
          },
          trailing: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
        ),
        //const Divider(),
        const LogoutWidget(),
      ],
    );
  }
}
