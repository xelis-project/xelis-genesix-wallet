import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:go_router/go_router.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/authentication/application/wallets_state_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:genesix/features/authentication/presentation/components/network_select_menu_tile.dart';

class OpenWalletScreen extends ConsumerStatefulWidget {
  const OpenWalletScreen({super.key});

  @override
  ConsumerState<OpenWalletScreen> createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final FSelectController<String> _selectController =
      FSelectController<String>(vsync: this);

  @override
  void dispose() {
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final network = ref.watch(
      settingsProvider.select((state) => state.network),
    );
    final wallets = ref.watch(walletsProvider.future);
    final appTheme = ref.watch(
      settingsProvider.select((state) => state.appTheme),
    );

    final isDarkMode = appTheme == AppTheme.dark || appTheme == AppTheme.xelis;

    return FScaffold(
      header: FHeader.nested(
        suffixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction(
              icon: Icon(FIcons.settings),
              onPress: () => context.push(AppScreen.lightSettings.toPath),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Spacer(flex: 2),
          Hero(
            tag: 'genesix-logo',
            child: ScalableImageWidget(
              si: isDarkMode
                  ? AppResources.svgGenesixWalletOneLineWhite
                  : AppResources.svgGenesixWalletOneLineBlack,
            ),
          ),
          Spacer(),
          Container(
            width: context.mediaWidth * 0.9,
            constraints: BoxConstraints(maxWidth: context.theme.breakpoints.sm),
            child: FCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        NetworkSelectMenuTile(
                          onSelected: (_) {
                            setState(() {
                              _selectController.value = null;
                            });
                          },
                        ),
                        FutureBuilder(
                          future: wallets,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data!.wallets.isNotEmpty) {
                              final initialWallet = switch (network) {
                                Network.mainnet =>
                                  snapshot.data!.lastWalletsUsed.mainnet,
                                Network.testnet =>
                                  snapshot.data!.lastWalletsUsed.testnet,
                                Network.devnet =>
                                  snapshot.data!.lastWalletsUsed.devnet,
                                Network.stagenet =>
                                  snapshot.data!.lastWalletsUsed.stagenet,
                              };

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _selectController.value = initialWallet;
                              });

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: Spaces.medium),
                                  FSelect<String>.rich(
                                    controller: _selectController,
                                    hint: 'Select a wallet',
                                    contentScrollHandles: true,
                                    // autovalidateMode: AutovalidateMode.disabled,
                                    format: (s) => s,
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a wallet';
                                      }
                                      return null;
                                    },
                                    children: snapshot.data!.wallets.entries
                                        .map((entry) {
                                          return FSelectItem(
                                            value: entry.key,
                                            prefix: FAvatar.raw(
                                              child: HashiconWidget(
                                                hash: entry.value,
                                                size: const Size(25, 25),
                                              ),
                                            ),
                                            title: Text(entry.key),
                                            subtitle: Text(
                                              truncateText(entry.value),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                  const SizedBox(height: Spaces.large),
                                  FButton(
                                    onPress: () =>
                                        _handleOpenWalletButtonPressed(context),
                                    child: const Text('Open Wallet'),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  FDivider(),
                  FButton(
                    onPress: () {
                      context.push(AppScreen.createWallet.toPath);
                    },
                    child: const Text('Create Wallet'),
                  ),
                  const SizedBox(height: Spaces.medium),
                  FButton(
                    onPress: () {
                      context.push(AppScreen.importWallet.toPath);
                    },
                    child: const Text('Import Wallet'),
                  ),
                ],
              ),
            ),
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }

  Future<void> _handleOpenWalletButtonPressed(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final walletName = _selectController.value;
    if (walletName == null) return;

    // Try biometrics
    final opened = await _openWalletWithBiometrics(walletName);
    if (opened || !context.mounted) return;

    // Fallback to password dialog
    showFDialog<void>(
      context: context,
      builder: (dialogContext, style, animation) {
        return PasswordDialog(
          style,
          animation,
          onEnter: (password) => _openWallet(walletName, password),
        );
      },
    );
  }

  Future<bool> _openWalletWithBiometrics(String name) async {
    if (kIsWeb) return false;

    final loc = ref.read(appLocalizationsProvider);
    final biometrics = ref.read(biometricAuthProvider.notifier);

    final authenticated = await biometrics.authenticate(
      loc.please_authenticate_open_wallet,
    );
    if (!authenticated) return false;

    final secureStorage = ref.read(secureStorageProvider);
    final password = await secureStorage.read(key: name);
    if (password == null) {
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.password_not_found);
      return false;
    }

    await _openWallet(name, password);
    return true;
  }

  Future<void> _openWallet(String name, String password) async {
    context.loaderOverlay.show();
    try {
      await ref
          .read(authenticationProvider.notifier)
          .openWallet(name, password);

      // unlock biometric auth if locked
      if (!kIsWeb &&
          ref.read(biometricAuthProvider) ==
              BiometricAuthProviderStatus.locked) {
        ref
            .read(biometricAuthProvider.notifier)
            .updateStatus(BiometricAuthProviderStatus.ready);
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}
