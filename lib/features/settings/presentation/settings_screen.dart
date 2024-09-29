import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/presentation/components/logger_selector_widget.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/presentation/components/layout_widget.dart';
import 'package:genesix/features/settings/presentation/components/theme_selector_widget.dart';
import 'package:genesix/features/settings/presentation/components/language_selector_widget.dart';
import 'package:genesix/features/settings/presentation/components/network_selector_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/background_widget.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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

  Future<void> _resetPreferences(BuildContext context) async {
    final loc = ref.read(appLocalizationsProvider);
    try {
      await ref.read(sharedPreferencesProvider).clear();
      ref.invalidate(settingsProvider);

      ref
          .read(snackBarMessengerProvider.notifier)
          .showInfo(loc.preferences_reset_snackbar);
    } catch (e) {
      ref.read(snackBarMessengerProvider.notifier).showError(e.toString());
    }
  }

  void _showResetPreferencesDialog(BuildContext context) {
    final loc = ref.read(appLocalizationsProvider);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.reset_preferences),
          content: Text(
              '${loc.reset_preferences_dialog}\n\n${loc.do_you_want_to_continue}'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(loc.cancel_button),
            ),
            TextButton(
              onPressed: () => context.pop(_resetPreferences(context)),
              child: Text(loc.reset),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final activateLogger =
        ref.watch(settingsProvider.select((state) => state.activateLogger));

    return Background(
      child: Scaffold(
        appBar: GenericAppBar(
            title: loc.app_settings,
            actions: activateLogger
                ? [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Spaces.none,
                          Spaces.medium, Spaces.small, Spaces.none),
                      child: IconButton(
                        onPressed: () => context.push(AppScreen.logger.toPath),
                        icon: const Icon(Icons.feed_outlined),
                        tooltip: loc.logger,
                      ),
                    )
                  ]
                : null),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
              Spaces.large, Spaces.none, Spaces.large, Spaces.large),
          children: [
            const NetworkSelectorWidget(),
            const Divider(),
            const ThemeSelectorWidget(),
            const Divider(),
            const LanguageSelectorWidget(),
            const Divider(),
            const LoggerSelectorWidget(),
            const Divider(),
            HorizontalContainer(title: loc.version, value: _version),
            const Divider(),
            VerticalContainer(
                title: loc.wallets_directory, value: _walletsPath),
            const Divider(),
            VerticalContainer(title: loc.cache_directory, value: _cachePath),
            const Divider(),
            const SizedBox(height: Spaces.medium),
            OutlinedButton(
                onPressed: () => _showResetPreferencesDialog(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(Spaces.medium + 4),
                  side: BorderSide(
                    color: context.colors.error,
                    width: 1,
                  ),
                ),
                child: Text(
                  loc.reset_preferences,
                  style: context.titleMedium!.copyWith(
                      color: context.colors.error, fontWeight: FontWeight.w800),
                )),
          ],
        ),
      ),
    );
  }
}
