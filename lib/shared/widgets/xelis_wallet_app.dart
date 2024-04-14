import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/providers/scaffold_messenger_provider.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/dark.dart';
import 'package:genesix/shared/theme/light.dart';
import 'package:genesix/shared/theme/xelis.dart';
import 'package:genesix/shared/widgets/app_providers_initializer.dart';
import 'package:genesix/shared/widgets/components/global_bottom_loader_widget.dart';
import 'package:genesix/shared/widgets/components/network_bar_widget.dart';
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
    final appTheme = ref.watch(settingsProvider.select((state) => state.theme));
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);

    // using kDebugMode and call func every render to hot reload the theme
    ThemeData themeData;
    switch (appTheme) {
      case AppTheme.xelis:
        themeData = kDebugMode ? xelisTheme() : _xelisTheme;
      case AppTheme.dark:
        themeData = kDebugMode ? darkTheme() : _darkTheme;
      case AppTheme.light:
        themeData = kDebugMode ? lightTheme() : _lightTheme;
    }

    return GlobalBottomLoader(
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
          return AppProvidersInitializer(
            child: Material(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const NetworkTopWidget(),
                  Expanded(
                    child: child!,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> onWindowClose() async {
    await ref.read(authenticationProvider.notifier).logout();
  }
}
