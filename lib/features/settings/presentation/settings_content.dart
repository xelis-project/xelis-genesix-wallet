import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/authentication/application/authentication_provider.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/authentication_state.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/display_currency.dart';
import 'package:genesix/features/settings/presentation/components/network_select_menu_tile.dart';
import 'package:genesix/features/settings/presentation/components/offline_mode_toggle_tile.dart';
import 'package:genesix/features/settings/presentation/components/reset_preference_button.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'components/language_selector_dialog.dart';

class SettingsContent extends ConsumerStatefulWidget {
  const SettingsContent({super.key});

  @override
  ConsumerState createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<SettingsContent>
    with TickerProviderStateMixin {
  final _controller = ScrollController();
  String _walletsPath = '';
  String _cachePath = '';
  String _version = '';

  @override
  void initState() {
    super.initState();

    getAppCacheDirPath().then((path) {
      if (!mounted) return;
      setState(() {
        _cachePath = path;
      });
    });

    getAppWalletsDirPath().then((path) {
      if (!mounted) return;
      setState(() {
        _walletsPath = path;
      });
    });

    PackageInfo.fromPlatform().then((packageInfo) {
      if (!mounted) return;
      setState(() {
        _version = packageInfo.version;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final locale = ref.watch(settingsProvider.select((state) => state.locale));

    final authState = ref.watch(authenticationProvider);

    return FadedScroll(
      controller: _controller,
      fadeFraction: 0.08,
      child: SingleChildScrollView(
        controller: _controller,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spaces.small),
          child: Column(
            spacing: Spaces.medium,
            children: [
              FTileGroup(
                label: Text(loc.general),
                children: [
                  FTile(
                    prefix: Icon(FLucideIcons.languages),
                    title: Text(loc.language),
                    subtitle: Text(translateLocaleName(locale)),
                    suffix: Icon(FLucideIcons.chevronRight),
                    onPress: () {
                      showAppDialog<void>(
                        context: context,
                        builder: (context, style, animation) {
                          return LanguageSelectorDialog(style, animation);
                        },
                      );
                    },
                  ),
                  if (authState.isAuth)
                    FTile(
                      prefix: Icon(FLucideIcons.fingerprintPattern),
                      title: Text(loc.biometric_auth),
                      subtitle: Text(loc.enable_biometric_auth),
                      suffix: FSwitch(
                        value: ref.watch(
                          settingsProvider.select(
                            (state) => state.activateBiometricAuth,
                          ),
                        ),
                        onChange: (value) =>
                            _handleBiometricToggle(context, value),
                      ),
                    ),
                  offlineModeToggleTile(ref),
                ],
              ),
              if (!authState.isAuth) const NetworkSelectMenuTile(),
              if (authState.isAuth)
                FTileGroup(
                  label: Text(loc.wallet),
                  children: [
                    FTile(
                      prefix: Icon(FLucideIcons.dollarSign),
                      title: Text(loc.conversion_rate),
                      subtitle: Text(_currencySubtitle(ref)),
                      suffix: Icon(FLucideIcons.chevronRight),
                      onPress: () {
                        _showCurrencySelector(context, ref);
                      },
                    ),
                    FTile(
                      prefix: Icon(FLucideIcons.flame),
                      title: Text(loc.burn),
                      subtitle: Text(loc.unlock_burn_transfer),
                      suffix: FSwitch(
                        value: ref.watch(
                          settingsProvider.select((state) => state.unlockBurn),
                        ),
                        onChange: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .setUnlockBurn(value);
                        },
                      ),
                    ),
                    FTile(
                      prefix: Icon(FLucideIcons.newspaper),
                      title: Text(loc.news_feed),
                      subtitle: Text(loc.enable_news_feed),
                      suffix: FSwitch(
                        value: ref.watch(
                          settingsProvider.select(
                            (state) => state.enableNewsFeed,
                          ),
                        ),
                        onChange: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .setEnableNewsFeed(value);
                        },
                      ),
                    ),
                  ],
                ),
              FTileGroup(
                label: Text(loc.information.capitalize()),
                children: [
                  FTile(title: Text(loc.version), details: Text('v$_version')),
                  FTile(
                    title: Text(loc.wallets_directory.capitalizeAll()),
                    subtitle: SelectableText(_walletsPath),
                  ),
                  FTile(
                    title: Text(loc.cache_directory.capitalizeAll()),
                    subtitle: SelectableText(_cachePath),
                  ),
                ],
              ),
              ResetPreferenceButton(),
            ],
          ),
        ),
      ),
    );
  }

  String _currencySubtitle(WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final code = ref.watch(
      settingsProvider.select((state) => state.displayCurrency),
    );
    if (code == null) return loc.disabled;
    final currency = DisplayCurrency.fromCode(code);
    return currency?.label ?? loc.disabled;
  }

  void _showCurrencySelector(BuildContext context, WidgetRef ref) {
    final loc = ref.read(appLocalizationsProvider);
    final currentCode = ref.read(settingsProvider).displayCurrency;
    final currentCurrency = DisplayCurrency.fromCode(currentCode);

    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) {
        return AppDialog(
          clipBehavior: Clip.antiAlias,
          animation: animation,
          direction: Axis.horizontal,
          body: Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FSelect<DisplayCurrency?>.rich(
              label: Text(loc.conversion_rate),
              description: Text(loc.show_or_hide_conversion_rate),
              control: .managed(
                initial: currentCurrency,
                onChange: (currency) {
                  ref
                      .read(settingsProvider.notifier)
                      .setDisplayCurrency(currency?.code);
                  context.pop();
                },
              ),
              format: (currency) =>
                  currency == null ? loc.disabled : currency.label,
              children: [
                FSelectItem<DisplayCurrency?>(
                  title: Text(loc.disabled),
                  value: null,
                ),
                for (final currency in DisplayCurrency.values)
                  FSelectItem<DisplayCurrency?>(
                    title: Text(currency.label),
                    value: currency,
                  ),
              ],
            ),
          ),
          actions: [
            FButton(onPress: () => context.pop(), child: Text(loc.ok_button)),
          ],
        );
      },
    );
  }

  Future<void> _handleBiometricToggle(
    BuildContext context,
    bool enabled,
  ) async {
    if (!enabled) {
      ref.read(settingsProvider.notifier).setActivateBiometricAuth(false);
      return;
    }

    showAppDialog<void>(
      context: context,
      builder: (dialogContext, style, animation) {
        return PasswordDialog(
          animation,
          onEnter: (password) async {
            final authState = ref.read(authenticationProvider);
            if (authState is! SignedIn) {
              return;
            }

            final wallet = ref.read(activeWalletRepositoryProvider);
            if (wallet == null) {
              return;
            }

            try {
              await wallet.isValidPassword(password);

              await ref
                  .read(secureStorageProvider)
                  .write(key: authState.name, value: password);

              ref
                  .read(settingsProvider.notifier)
                  .setActivateBiometricAuth(true);

              if (dialogContext.mounted) {
                dialogContext.pop();
              }
            } catch (e) {
              ref
                  .read(toastProvider.notifier)
                  .showError(description: e.toString());
            }
          },
        );
      },
    );
  }
}
