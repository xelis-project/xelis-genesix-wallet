import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_commands_provider.dart';
import 'package:genesix/features/authentication/domain/biometric_wallet_key.dart';
import 'package:genesix/features/authentication/domain/wallet_session_command_result.dart';
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
import 'package:genesix/features/authentication/application/wallets_provider.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:genesix/features/authentication/presentation/components/current_network_indicator.dart';

class OpenWalletScreen extends ConsumerStatefulWidget {
  const OpenWalletScreen({super.key});

  @override
  ConsumerState<OpenWalletScreen> createState() => _OpenWalletWidgetState();
}

class _OpenWalletWidgetState extends ConsumerState<OpenWalletScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final FSelectController<String> _selectController =
      FSelectController<String>();

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
    ref.listen(settingsProvider.select((state) => state.network), (
      previous,
      next,
    ) {
      if (previous != next) {
        _selectController.value = null;
        _formKey.currentState?.reset();
      }
    });
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
              icon: Icon(FLucideIcons.settings),
              onPress: () => context.push(AppScreen.lightSettings.toPath),
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Hero(
            tag: 'genesix-logo',
            child: ScalableImageWidget(
              si: isDarkMode
                  ? AppResources.svgGenesixWalletOneLineWhite
                  : AppResources.svgGenesixWalletOneLineBlack,
            ),
          ),
          Spacer(),
          const CurrentNetworkIndicator(),
          const SizedBox(height: Spaces.medium),
          Container(
            width: context.mediaWidth * 0.9,
            constraints: BoxConstraints(maxWidth: context.theme.breakpoints.sm),
            child: FCard(
              child: FutureBuilder(
                future: wallets,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.wallets.isNotEmpty) {
                    final initialWallet = switch (network) {
                      Network.mainnet => snapshot.data!.lastWalletsUsed.mainnet,
                      Network.testnet => snapshot.data!.lastWalletsUsed.testnet,
                      Network.devnet => snapshot.data!.lastWalletsUsed.devnet,
                      Network.stagenet =>
                        snapshot.data!.lastWalletsUsed.stagenet,
                    };

                    final initialWalletExists =
                        initialWallet != null &&
                        snapshot.data!.wallets.containsKey(initialWallet);

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (_selectController.value == null) {
                        _selectController.value = initialWalletExists
                            ? initialWallet
                            : null;
                      }
                    });

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: Spaces.medium),
                              FSelect<String>.rich(
                                control: .managed(
                                  controller: _selectController,
                                  onChange: _handleWalletSelected,
                                ),
                                hint: loc.select_wallet,
                                // contentScrollHandles: true,
                                // autovalidateMode: AutovalidateMode.disabled,
                                format: (s) => s,
                                validator: (value) {
                                  if (value == null) {
                                    return loc.please_select_wallet;
                                  }
                                  return null;
                                },
                                children: snapshot.data!.wallets.entries.map((
                                  entry,
                                ) {
                                  return FSelectItem(
                                    value: entry.key,
                                    prefix: FAvatar.raw(
                                      child: HashiconWidget(
                                        hash: entry.value,
                                        size: const Size(25, 25),
                                      ),
                                    ),
                                    title: Text(entry.key),
                                    subtitle: Text(truncateText(entry.value)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: Spaces.large),
                              FButton(
                                onPress: () =>
                                    _handleOpenWalletButtonPressed(context),
                                child: Text(loc.open_wallet),
                              ),
                            ],
                          ),
                        ),
                        FDivider(),
                        _OpenWalletActions(),
                      ],
                    );
                  }

                  if (snapshot.hasData) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NoWalletsContent(message: loc.no_wallet_available),
                        const SizedBox(height: Spaces.large),
                        _OpenWalletActions(),
                      ],
                    );
                  }

                  return const SizedBox(
                    height: 120,
                    child: Center(child: FCircularProgress()),
                  );
                },
              ),
            ),
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }

  void _handleWalletSelected(String? _) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _formKey.currentState?.validate();
    });
  }

  Future<void> _handleOpenWalletButtonPressed(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final walletName = _selectController.value;
    if (walletName == null) return;

    // Try biometrics
    final opened = await _openWalletWithBiometrics(walletName);
    if (opened || !context.mounted) return;

    // Fallback to password dialog
    showAppDialog<void>(
      context: context,
      builder: (dialogContext, _, animation) {
        return PasswordDialog(
          animation,
          onEnter: (password) => _openWallet(walletName, password),
        );
      },
    );
  }

  Future<bool> _openWalletWithBiometrics(String name) async {
    if (kIsWeb) return false;

    final loc = ref.read(appLocalizationsProvider);
    final network = ref.read(settingsProvider).network;
    final secureStorage = ref.read(secureStorageProvider);
    final isEnabledForWallet = await secureStorage.containsKey(
      key: biometricWalletKey(network: network, walletName: name),
    );
    if (!isEnabledForWallet) {
      return false;
    }

    final authenticated = await ref.read(
      biometricAuthenticationProvider(
        loc.please_authenticate_open_wallet,
      ).future,
    );

    if (!authenticated) return false;

    final password = await secureStorage.read(key: name);
    if (password == null) {
      ref
          .read(toastProvider.notifier)
          .showError(description: loc.password_not_found);
      return false;
    }

    return _openWallet(name, password);
  }

  Future<bool> _openWallet(String name, String password) async {
    context.loaderOverlay.show();
    try {
      final result = await ref
          .read(walletSessionCommandsProvider.notifier)
          .openWallet(name, password);
      if (result is WalletSessionCommandSuccess && mounted) {
        context.go(AuthAppScreen.home.toPath, extra: result.seedToReveal);
        return true;
      }
      return false;
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}

class _NoWalletsContent extends StatelessWidget {
  const _NoWalletsContent({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spaces.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Spaces.small,
        children: [
          Icon(
            FLucideIcons.wallet,
            size: 28,
            color: context.theme.colors.mutedForeground,
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenWalletActions extends ConsumerWidget {
  const _OpenWalletActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FButton(
          variant: .outline,
          onPress: () {
            context.push(AppScreen.createWallet.toPath);
          },
          child: Text(loc.create_wallet),
        ),
        const SizedBox(height: Spaces.medium),
        FButton(
          variant: .outline,
          onPress: () {
            context.push(AppScreen.importWallet.toPath);
          },
          child: Text(loc.import_wallet),
        ),
      ],
    );
  }
}
