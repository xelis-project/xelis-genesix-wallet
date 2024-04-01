import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/router/router.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/settings_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/settings_state.dart';
import 'package:xelis_mobile_wallet/shared/providers/scaffold_messenger_provider.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/flex_theme.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/network_bar_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/snackbar_initializer_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/wallet_initializer_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class XelisWalletApp extends ConsumerStatefulWidget {
  const XelisWalletApp({super.key});

  @override
  ConsumerState<XelisWalletApp> createState() => _XelisWalletAppState();
}

class _XelisWalletAppState extends ConsumerState<XelisWalletApp>
    with WindowListener {
  final _lightTheme = lightTheme();
  final _darkTheme = darkTheme();
  final _xelisTheme = xelisTheme();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);

    ThemeData themeData;
    switch (settings.theme) {
      case AppTheme.xelis:
        themeData = _xelisTheme;
      case AppTheme.dark:
        themeData = _darkTheme;
      case AppTheme.light:
        themeData = _lightTheme;
    }

    return WalletInitializerWidget(
      child: GlobalLoaderOverlay(
        useDefaultLoading: false,
        overlayWidgetBuilder: (_) {
          Color loadingWidgetColor;
          /*switch (settings.theme) {
            case ThemeMode.system:
              if (context.mediaQueryData.platformBrightness ==
                  Brightness.light) {
                loadingWidgetColor = _lightTheme.primaryColor;
              } else {
                loadingWidgetColor = _darkTheme.primaryColor;
              }
            case ThemeMode.light:
              loadingWidgetColor = _lightTheme.primaryColor;
            case ThemeMode.dark:
              loadingWidgetColor = _darkTheme.primaryColor;
          }*/

          return Center(
              child: CircularProgressIndicator(
                  //color: loadingWidgetColor,
                  ));
        },
        child: MaterialApp.router(
          title: AppResources.xelisWalletName,
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,
          theme: themeData,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NetworkTopWidget(),
                Expanded(child: SnackBarInitializerWidget(child: child!)),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Future<void> onWindowClose() async {
    await ref.read(authenticationProvider.notifier).logout();
  }
}
