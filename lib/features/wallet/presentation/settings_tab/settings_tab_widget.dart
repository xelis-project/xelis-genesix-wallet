import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/network_wallet_state_provider.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/utils/utils.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/password_dialog.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  void _deleteWallet(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final walletSnapshot = ref.read(walletStateProvider);
    final auth = ref.read(authenticationProvider.notifier);
    final networkWallets = ref.read(networkWalletProvider.notifier);

    try {
      var walletPath =
          await getWalletPath(settings.network, walletSnapshot.name);
      await Directory(walletPath).delete(recursive: true);
      networkWallets.removeWallet(settings.network, walletSnapshot.name);
      await auth.logout();
    } catch (e) {
      ref
          .read(snackbarContentProvider.notifier)
          .setContent(SnackbarEvent.error(message: e.toString()));
    }
  }

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
          title: Wrap(
            spacing: Spaces.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(Icons.settings_applications),
              Text(
                'App settings',
                style: context.titleLarge,
              )
            ],
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
                'View seed',
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
        const Divider(),
        const SizedBox(
          height: Spaces.large,
        ),
        OutlinedButton.icon(
          icon: Icon(
            Icons.delete_forever,
            color: context.colors.error,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            side: BorderSide(
              color: context.colors.error,
              width: 2,
            ),
          ),
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return PasswordDialog(
                  onValid: () => _deleteWallet(ref),
                );
              },
            );
          },
          label: Text(
            'Delete wallet',
            style: context.titleLarge!.copyWith(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}
