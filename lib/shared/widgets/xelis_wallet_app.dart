import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/router/router.dart';
import 'package:xelis_mobile_wallet/shared/providers/scaffold_messenger_provider.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/xelis.dart';
import 'package:xelis_mobile_wallet/shared/widgets/app_providers_initializer.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/global_bottom_loader_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/network_bar_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/snackbar_initializer_widget.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/wallet_initializer_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class XelisWalletApp extends ConsumerStatefulWidget {
  const XelisWalletApp({super.key});

  @override
  ConsumerState<XelisWalletApp> createState() => _XelisWalletAppState();
}

class _XelisWalletAppState extends ConsumerState<XelisWalletApp>
    with WindowListener {
  //final _lightTheme = lightTheme();
  //final _darkTheme = darkTheme();
  //final _xelisTheme = xelisTheme();

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
    //final settings = ref.watch(settingsProvider);
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);

    // using kDebugMode and call func every render to hot reload the theme
    /*ThemeData themeData;
    switch (settings.theme) {
      case AppTheme.xelis:
      // themeData = kDebugMode ? xelisTheme() : _xelisTheme;
      case AppTheme.dark:
      //themeData = kDebugMode ? darkTheme() : _xelisTheme;
      case AppTheme.light:
      // themeData = kDebugMode ? lightTheme() : _xelisTheme;
    }*/
    return AppProvidersInitializer(
      child: GlobalBottomLoader(
        child: MaterialApp.router(
          title: AppResources.xelisWalletName,
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light,
          //theme: themeData,
          theme: xelisTheme(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return Material(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NetworkTopWidget(),
                  Expanded(
                    child: child!,
                  ),
                ],
              ),
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
