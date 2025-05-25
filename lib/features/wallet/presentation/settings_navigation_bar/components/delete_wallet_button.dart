import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
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
      icon: Icon(Icons.delete_forever, color: context.colors.error),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(Spaces.medium + 4),
        side: BorderSide(color: context.colors.error, width: 1),
      ),
      onPressed: () => _showConfirmationDialog(
        ref,
        title: loc.delete_wallet_warning_message,
      ),
      label: Text(
        loc.delete_wallet,
        style: context.titleMedium!.copyWith(
          color: context.colors.error,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showConfirmationDialog(WidgetRef ref, {required String title}) {
    final loc = ref.read(appLocalizationsProvider);
    showDialog<void>(
      context: ref.context,
      builder: (context) {
        return ConfirmDialog(
          title: title,
          onConfirm: (yes) async {
            if (yes) {
              startWithBiometricAuth(
                ref,
                callback: (ref) {
                  final walletSnapshot = ref.read(walletStateProvider);
                  final wallets = ref.read(walletsProvider.notifier);
                  wallets
                      .deleteWallet(walletSnapshot.name)
                      .then(
                        (value) {
                          ref
                              .read(snackBarQueueProvider.notifier)
                              .showInfo(loc.wallet_deleted);
                        },
                        onError: (Object e) {
                          ref
                              .read(snackBarQueueProvider.notifier)
                              .showError(e.toString());
                        },
                      );
                },
                reason: loc.please_authenticate_delete_wallet,
                closeCurrentDialog: true,
              );
            }
          },
        );
      },
    );
  }
}
