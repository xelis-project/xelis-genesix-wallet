import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/confirm_dialog.dart';

class DeleteWalletButton extends ConsumerStatefulWidget {
  const DeleteWalletButton({super.key});

  @override
  ConsumerState createState() => _DeleteWalletButtonState();
}

class _DeleteWalletButtonState extends ConsumerState<DeleteWalletButton> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return OutlinedButton.icon(
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
      onPressed: () => startWithBiometricAuth(
        ref,
        callback: _deleteWallet,
        closeCurrentDialog: false,
      ),
      label: Text(
        loc.delete_wallet,
        style: context.titleMedium!
            .copyWith(color: context.colors.error, fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _deleteWallet(WidgetRef ref) async {
    await showDialog<void>(
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
}
