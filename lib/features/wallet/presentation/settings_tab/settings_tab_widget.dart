import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/widgets/components/confirm_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/input_dialog.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  void _deleteWallet(WidgetRef ref) {
    showDialog<void>(
      context: ref.context,
      builder: (context) {
        return ConfirmDialog(
          onConfirm: (yes) async {
            if (yes) {
              final walletSnapshot = ref.read(walletStateProvider);
              final wallets = ref.read(walletsProvider.notifier);

              try {
                await wallets.deleteWallet(walletSnapshot.name);
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showInfo('Wallet was deleted.');
              } catch (e) {
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showError(e.toString());
              }
            }
          },
        );
      },
    );
  }

  void _showDeleteWalletInput(WidgetRef ref) {
    showDialog<void>(
        context: ref.context,
        builder: (context) {
          return PasswordDialog(
            closeOnValid: false,
            onValid: () {
              _deleteWallet(ref);
            },
          );
        });
  }

  void _renameWallet(WidgetRef ref, String newName) {
    showDialog<void>(
      context: ref.context,
      builder: (context) {
        return ConfirmDialog(
          onConfirm: (yes) async {
            if (yes) {
              try {
                final walletSnapshot = ref.read(walletStateProvider);
                final wallets = ref.read(walletsProvider.notifier);

                await wallets.renameWallet(walletSnapshot.name, newName);
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showInfo('Wallet was renamed.');
              } catch (e) {
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showError(e.toString());
              }
            }
          },
        );
      },
    );
  }

  void _showRenameWalletInput(WidgetRef ref) {
    showDialog<void>(
      context: ref.context,
      builder: (context) {
        return InputDialog(
          hintText: 'New name',
          onEnter: (value) {
            _renameWallet(ref, value);
          },
        );
      },
    );
  }

  void _showSeedInput(BuildContext context) {
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return ListView(
      padding: const EdgeInsets.all(Spaces.large),
      children: [
        Text(
          loc.settings,
          style: context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Spaces.large),
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
          onTap: () => context.push(AppScreen.settings.toPath),
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
          onTap: () => _showSeedInput(context),
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
              const Icon(Icons.edit),
              Text(
                'Rename wallet',
                style: context.titleLarge,
              )
            ],
          ),
          onTap: () => _showRenameWalletInput(ref),
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
          onTap: () => context.push(AppScreen.changePassword.toPath),
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
            padding: const EdgeInsets.all(Spaces.large),
            side: BorderSide(
              color: context.colors.error,
              width: 2,
            ),
          ),
          onPressed: () => _showDeleteWalletInput(ref),
          label: Text(
            'Delete wallet',
            style: context.titleLarge!.copyWith(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}
