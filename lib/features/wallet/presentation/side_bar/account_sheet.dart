import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/side_bar/change_password_dialog.dart';
import 'package:genesix/features/wallet/presentation/side_bar/wallet_name_widget.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/confirm_dialog.dart';
import 'package:genesix/shared/widgets/components/sheet_content.dart';

class AccountSheet extends ConsumerStatefulWidget {
  const AccountSheet({super.key});

  @override
  ConsumerState createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<AccountSheet> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletAddress = ref.watch(
      walletStateProvider.select((state) => state.address),
    );

    return SheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WalletNameWidget(),
          const SizedBox(height: Spaces.small),
          Row(
            spacing: Spaces.medium,
            children: [
              Expanded(
                child: Text(
                  walletAddress,
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ),
              FTooltip(
                tipBuilder: (context, controller) => Text(loc.copy),
                child: FButton.icon(
                  onPress: () =>
                      copyToClipboard(walletAddress, ref, loc.copied),
                  child: const Icon(FIcons.copy),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spaces.extraLarge),
          FButton(
            style: FButtonStyle.secondary(),
            prefix: Icon(FIcons.keyRound),
            onPress: _showChangePasswordDialog,
            child: Text(loc.change_password),
          ),
          const SizedBox(height: Spaces.small),
          FButton(
            style: FButtonStyle.destructive(),
            prefix: Icon(FIcons.trash),
            onPress: _showDeleteWalletDialog,
            child: Text(loc.delete_wallet.capitalizeAll()),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showFDialog<void>(
      useRootNavigator: true,
      context: context,
      builder: (context, style, animation) {
        return ChangePasswordDialog();
      },
    );
  }

  void _showDeleteWalletDialog() {
    final loc = ref.read(appLocalizationsProvider);
    showFDialog<void>(
      useRootNavigator: true,
      context: ref.context,
      builder: (context, style, animation) {
        return ConfirmDialog(
          style: style,
          animation: animation,
          description: loc.delete_wallet_confirmation,
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
                              .read(toastProvider.notifier)
                              .showEvent(description: loc.wallet_deleted);
                        },
                        onError: (Object e) {
                          ref
                              .read(toastProvider.notifier)
                              .showError(description: e.toString());
                        },
                      );
                },
                reason: loc.please_authenticate_delete_wallet,
                closeCurrentDialog: false,
              );
            }
          },
        );
      },
    );
  }
}
