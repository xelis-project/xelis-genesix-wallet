import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
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
              final loc = ref.read(appLocalizationsProvider);

              try {
                await wallets.deleteWallet(walletSnapshot.name);
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showInfo(loc.wallet_deleted);
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
                final loc = ref.read(appLocalizationsProvider);

                await wallets.renameWallet(walletSnapshot.name, newName);
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showInfo(loc.wallet_renamed);
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
        final loc = ref.read(appLocalizationsProvider);
        return InputDialog(
          hintText: loc.new_name,
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
            context.push(AuthAppScreen.walletSeedScreen.toPath);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final hideZeroTransfer =
        ref.watch(settingsProvider.select((value) => value.hideZeroTransfer));
    final hideExtraData =
        ref.watch(settingsProvider.select((value) => value.hideExtraData));
    final name = ref.watch(walletStateProvider.select((state) => state.name));

    return ListView(
      padding: const EdgeInsets.all(Spaces.large),
      children: [
        Text(
          loc.settings,
          style: context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Spaces.medium),
        ListTile(
          leading: const Icon(Icons.settings_applications),
          title: Text(
            loc.app_settings,
            style: context.titleLarge,
          ),
          onTap: () => context.push(AppScreen.settings.toPath),
          trailing: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.pattern_rounded),
          title: Text(
            loc.view_seed,
            style: context.titleLarge,
          ),
          onTap: () => _showSeedInput(context),
          trailing: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit),
          title: Text(
            loc.rename_wallet,
            style: context.titleLarge,
          ),
          subtitle: Text(
            name,
            style: context.titleMedium!.copyWith(color: context.colors.primary),
          ),
          onTap: () => _showRenameWalletInput(ref),
          trailing: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.password),
          title: Text(
            loc.change_password,
            style: context.titleLarge,
          ),
          onTap: () => context.push(AuthAppScreen.changePassword.toPath),
          trailing: const Icon(
            Icons.keyboard_arrow_right_rounded,
          ),
        ),
        const Divider(),
        ExpansionTile(
          leading: const Icon(Icons.widgets_outlined),
          title: Text(
            loc.history_parameters,
            style: context.titleLarge,
          ),
          children: [
            FormBuilderSwitch(
              name: 'zero_transfer_switch',
              initialValue: hideZeroTransfer,
              decoration: const InputDecoration(fillColor: Colors.transparent),
              title: Text(loc.hide_zero_transfers, style: context.bodyLarge),
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setHideZeroTransfer(value!);
              },
            ),
            FormBuilderSwitch(
              name: 'extra_data_switch',
              initialValue: hideExtraData,
              decoration: const InputDecoration(fillColor: Colors.transparent),
              title: Text(loc.hide_extra_data, style: context.bodyLarge),
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setHideExtraData(value!);
              },
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: Spaces.medium),
        OutlinedButton.icon(
          icon: Icon(
            Icons.delete_forever,
            color: context.colors.error,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(Spaces.medium + 4),
            side: BorderSide(
              color: context.colors.error,
              width: 1,
            ),
          ),
          onPressed: () => _showDeleteWalletInput(ref),
          label: Text(
            loc.delete_wallet,
            style: context.titleMedium!.copyWith(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}
