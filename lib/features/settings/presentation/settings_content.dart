import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/presentation/components/reset_preference_button.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'components/language_selector_dialog.dart';

class SettingsContent extends ConsumerStatefulWidget {
  const SettingsContent({super.key});

  @override
  ConsumerState createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<SettingsContent> {
  final _controller = ScrollController();
  String _walletsPath = '';
  String _cachePath = '';
  String _version = '';

  @override
  void initState() {
    super.initState();

    getAppCacheDirPath().then((path) {
      setState(() {
        _cachePath = path;
      });
    });

    getAppWalletsDirPath().then((path) {
      setState(() {
        _walletsPath = path;
      });
    });

    PackageInfo.fromPlatform().then((packageInfo) {
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
                    prefix: Icon(FIcons.languages),
                    title: Text(loc.language),
                    subtitle: Text(translateLocaleName(locale)),
                    suffix: Icon(FIcons.chevronRight),
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
                      prefix: Icon(FIcons.fingerprint),
                      title: Text(loc.biometric_auth),
                      subtitle: Text(loc.enable_biometric_auth),
                      suffix: FSwitch(
                        value: ref.watch(
                          settingsProvider.select(
                            (state) => state.activateBiometricAuth,
                          ),
                        ),
                        onChange: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .setActivateBiometricAuth(value);
                        },
                      ),
                    ),
                ],
              ),
              if (authState.isAuth)
                FTileGroup(
                  label: Text(loc.wallet),
                  children: [
                    FTile(
                      prefix: Icon(FIcons.dollarSign),
                      title: Text(loc.conversion_rate),
                      subtitle: Text(loc.show_or_hide_conversion_rate),
                      suffix: FSwitch(
                        value: ref.watch(
                          settingsProvider.select(
                            (state) => state.showBalanceUSDT,
                          ),
                        ),
                        onChange: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .setShowBalanceUSDT(value);
                        },
                      ),
                    ),
                    FTile(
                      prefix: Icon(FIcons.cable),
                      title: Text(loc.xswd_status),
                      subtitle: Text(loc.xswd_setting_label),
                      suffix: FSwitch(
                        value: ref.watch(
                          settingsProvider.select((state) => state.enableXswd),
                        ),
                        onChange: (value) {
                          ref
                              .read(settingsProvider.notifier)
                              .setEnableXswd(value);
                        },
                      ),
                    ),
                    FTile(
                      prefix: Icon(FIcons.flame),
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
}
