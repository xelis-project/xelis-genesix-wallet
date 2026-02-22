import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/presentation/settings_navigation_bar/components/burn_warning_dialog.dart';
import 'package:genesix/features/wallet/presentation/settings_navigation_bar/components/delete_wallet_button_old.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/input_dialog.dart';

class SettingsNavigationBar extends ConsumerWidget {
  SettingsNavigationBar({super.key});

  final _burnSwitchKey = GlobalKey<FormBuilderFieldState<dynamic, dynamic>>(
    debugLabel: '_burnSwitchKey',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final name = ref.watch(walletStateProvider.select((state) => state.name));
    final settings = ref.watch(settingsProvider);
    // final isBiometricAuthLocked =
    //     ref.watch(biometricAuthProvider) == BiometricAuthProviderStatus.locked;

    return ListView(
      padding: const EdgeInsets.all(Spaces.large),
      children: [
        const SizedBox(height: Spaces.medium),
        ListTile(
          leading: const Icon(Icons.settings_applications),
          title: Text(loc.app_settings, style: context.titleLarge),
          onTap: () => context.push(AppScreen.lightSettings.toPath),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
        if (!kIsWeb) ...[
          // We don't want to show the XSWD status because XSWD protocol is not supported on web
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security_rounded),
            title: Text(loc.xswd_status, style: context.titleLarge),
            subtitle: Text(
              loc.xswd_setting_label,
              style: context.labelMedium?.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            onTap: () => context.push(AuthAppScreen.xswd.toPath),
            trailing: const Icon(Icons.keyboard_arrow_right_rounded),
          ),
        ],
        const Divider(),
        ListTile(
          leading: const Icon(Icons.my_library_books_outlined),
          title: Text(loc.address_book, style: context.titleLarge),
          onTap: () => context.push(AuthAppScreen.addressBook.toPath),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.pattern_rounded),
          title: Text(loc.view_seed, style: context.titleLarge),
          onTap: () => startWithBiometricAuth(
            ref,
            // callback: (ref) =>
            //     ref.context.push(AuthAppScreen.walletSeedScreen.toPath),
            callback: (ref) {},
            reason: loc.please_authenticate_view_seed,
          ),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
        const Divider(),
        ExpansionTile(
          leading: const Icon(Icons.wallet_membership_rounded),
          title: Text(
            loc.wallet_parameters.capitalize(),
            style: context.titleLarge,
          ),
          children: [
            FormBuilderSwitch(
              name: 'biometric_auth_switch',
              initialValue: settings.activateBiometricAuth,
              decoration: const InputDecoration(fillColor: Colors.transparent),
              title: Text(loc.enable_biometric_auth, style: context.bodyLarge),
              onChanged: (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setActivateBiometricAuth(value!);
              },
            ),
            if (settings.network == Network.mainnet)
              FormBuilderSwitch(
                name: 'show_balance_usdt_switch',
                initialValue: settings.displayCurrency != null,
                decoration: const InputDecoration(
                  fillColor: Colors.transparent,
                ),
                title: Text(
                  loc.show_balance_usdt.capitalize(),
                  style: context.bodyLarge,
                ),
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setDisplayCurrency(value! ? 'usd' : null);
                },
              ),
            FormBuilderSwitch(
              name: 'unlock_burn_switch',
              key: _burnSwitchKey,
              initialValue: settings.unlockBurn,
              decoration: const InputDecoration(fillColor: Colors.transparent),
              title: Text(
                loc.unlock_burn_transfer.capitalize(),
                style: context.bodyLarge,
              ),
              onChanged: (value) => _showBurnWarningDialog(ref, value ?? false),
            ),
          ],
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.edit),
          title: Text(loc.rename_wallet, style: context.titleLarge),
          subtitle: Text(
            name,
            style: context.titleMedium!.copyWith(color: context.colors.primary),
          ),
          onTap: () => _showRenameWalletInput(ref),
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.password),
          title: Text(loc.change_password, style: context.titleLarge),
          // onTap: () => context.push(AuthAppScreen.changePassword.toPath),
          onTap: () {},
          trailing: const Icon(Icons.keyboard_arrow_right_rounded),
        ),
        const Divider(),
        const SizedBox(height: Spaces.medium),
        Row(
          children: [
            if (context.isWideScreen) Spacer(),
            Expanded(child: DeleteWalletButton()),
            if (context.isWideScreen) Spacer(),
          ],
        ),
      ],
    );
  }

  // void _renameWallet(WidgetRef ref, String newName) {
  //   showDialog<void>(
  //     context: ref.context,
  //     builder: (context) {
  //       return ConfirmDialog(
  //         onConfirm: (yes) async {
  //           if (yes) {
  //             try {
  //               final walletSnapshot = ref.read(walletStateProvider);
  //               final wallets = ref.read(walletsProvider.notifier);
  //               final loc = ref.read(appLocalizationsProvider);
  //
  //               await wallets.renameWallet(walletSnapshot.name, newName);
  //               ref
  //                   .read(toastProvider.notifier)
  //                   .showEvent(description: loc.wallet_renamed);
  //             } catch (e) {
  //               ref
  //                   .read(toastProvider.notifier)
  //                   .showError(description: e.toString());
  //             }
  //           }
  //         },
  //       );
  //     },
  //   );
  // }

  void _showRenameWalletInput(WidgetRef ref) {
    showDialog<void>(
      context: ref.context,
      builder: (context) {
        final loc = ref.read(appLocalizationsProvider);
        return InputDialog(
          title: loc.rename_wallet,
          hintText: loc.new_name,
          onEnter: (value) {
            // _renameWallet(ref, value);
          },
        );
      },
    );
  }

  Future<void> _showBurnWarningDialog(WidgetRef ref, bool switchValue) async {
    _burnSwitchKey.currentState?.save();
    if (switchValue) {
      await showDialog<void>(
        context: ref.context,
        builder: (context) {
          return BurnWarningDialog();
        },
      );
      final unlockBurn = ref.read(settingsProvider).unlockBurn;
      // If the user cancels or aborts the burn unlock, we need to reset the switch
      if (!unlockBurn) {
        _burnSwitchKey.currentState?.didChange(false);
      }
    } else {
      ref.read(settingsProvider.notifier).setUnlockBurn(false);
    }
  }
}
