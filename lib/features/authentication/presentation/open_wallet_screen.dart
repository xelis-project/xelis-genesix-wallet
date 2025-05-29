import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/presentation/components/add_wallet_modal_bottom_sheet.dart';
import 'package:genesix/shared/providers/snackbar_queue_provider.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';

class OpenWalletScreen extends ConsumerStatefulWidget {
  const OpenWalletScreen({super.key});

  @override
  ConsumerState<OpenWalletScreen> createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletScreen> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final wallets = ref.watch(walletsProvider);

    return CustomScaffold(
      body: Padding(
        padding: const EdgeInsets.all(Spaces.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.your_wallets, style: context.headlineMedium),
                IconButton(
                  onPressed: () {
                    context.push(AppScreen.settings.toPath);
                  },
                  icon: Icon(
                    Icons.settings,
                    color: context.moreColors.mutedColor,
                    size: 30,
                  ),
                  tooltip: loc.settings,
                ),
              ],
            ),
            const SizedBox(height: Spaces.small),
            Expanded(
              child: wallets.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(Spaces.small),
                      decoration: BoxDecoration(
                        color: context.colors.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ReorderableListView(
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: context.colors.surface.withValues(
                              alpha: 0.5,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: child,
                          );
                        },
                        children: <Widget>[
                          for (final name in wallets.keys)
                            Material(
                              color: Colors.transparent,
                              key: Key(name),
                              child: InkWell(
                                onTap: () async {
                                  if (!await _openWalletWithBiometrics(name)) {
                                    if (context.mounted) {
                                      showDialog<void>(
                                        context: context,
                                        builder: (context) {
                                          return PasswordDialog(
                                            onEnter: (password) {
                                              _openWallet(name, password);
                                            },
                                          );
                                        },
                                      );
                                    }
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(Spaces.small),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      wallets[name]!.isNotEmpty
                                          ? HashiconWidget(
                                              hash: wallets[name]!,
                                              size: const Size(50, 50),
                                            )
                                          : const SizedBox(
                                              width: 50,
                                              height: 50,
                                            ),
                                      const SizedBox(width: Spaces.small),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: context.headlineSmall,
                                            ),
                                            Text(
                                              truncateText(wallets[name]!),
                                              style: context.labelLarge!
                                                  .copyWith(
                                                    color: context
                                                        .moreColors
                                                        .mutedColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 30),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                        onReorder: (int oldIndex, int newIndex) {
                          // https://api.flutter.dev/flutter/widgets/ReorderCallback.html
                          if (oldIndex < newIndex) {
                            // removing the item at oldIndex will shorten the list by 1.
                            newIndex -= 1;
                          }

                          var name = wallets.keys.elementAt(oldIndex);
                          final w = ref.read(walletsProvider.notifier);
                          w.orderWallet(name, newIndex);
                        },
                      ),
                    )
                  : Text(
                      loc.no_wallet_available,
                      style: context.bodyMedium!.copyWith(
                        color: context.moreColors.mutedColor,
                        fontSize: 18,
                      ),
                    ),
            ),
            const SizedBox(height: Spaces.large),
            Row(
              children: [
                IconButton.filled(
                  onPressed: () => _showAddWalletModalBottomSheetMenu(),
                  icon: Icon(
                    Icons.add_rounded,
                    size: 30,
                    color: context.colors.onPrimary,
                  ),
                ),
                const SizedBox(width: Spaces.small),
                Text(
                  loc.add_a_wallet,
                  style: context.bodyLarge!.copyWith(
                    color: context.moreColors.mutedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddWalletModalBottomSheetMenu() async {
    final importedWalletData =
        await showModalBottomSheet<({String path, String walletName})?>(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return const AddWalletModalBottomSheetMenu();
          },
        );

    // only used for desktop wallet import
    if (importedWalletData != null) {
      final password = await _getPassword();
      if (password != null) {
        _openImportedWallet(
          importedWalletData.path,
          importedWalletData.walletName,
          password,
        );
      }
    }
  }

  Future<void> _openImportedWallet(
    String path,
    String walletName,
    String password,
  ) async {
    context.loaderOverlay.show();

    await ref
        .read(authenticationProvider.notifier)
        .openImportedWallet(path, walletName, password);

    if (mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }

  Future<String?> _getPassword() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        return PasswordDialog(
          onEnter: (password) {
            context.pop(password);
          },
        );
      },
    );
  }

  void _openWallet(String name, String password) async {
    context.loaderOverlay.show();

    await ref.read(authenticationProvider.notifier).openWallet(name, password);

    // unlock biometric auth if locked
    if (ref.read(biometricAuthProvider) == BiometricAuthProviderStatus.locked) {
      ref
          .read(biometricAuthProvider.notifier)
          .updateStatus(BiometricAuthProviderStatus.ready);
    }

    if (mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
  }

  Future<bool> _openWalletWithBiometrics(String name) async {
    final loc = ref.read(appLocalizationsProvider);
    final secureStorage = ref.read(secureStorageProvider);
    final authenticated = await ref
        .read(biometricAuthProvider.notifier)
        .authenticate(loc.please_authenticate_open_wallet);
    if (authenticated) {
      final password = await secureStorage.read(key: name);
      if (password != null) {
        _openWallet(name, password);
        return true;
      } else {
        ref
            .read(snackBarQueueProvider.notifier)
            .showError(loc.password_not_found);
      }
    }
    return false;
  }
}
