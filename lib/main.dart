import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/features/router/router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/providers/scaffold_messenger_provider.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/flex_theme.dart';
import 'package:xelis_mobile_wallet/shared/widgets/wallet_initializer_widget.dart';
import 'package:xelis_mobile_wallet/src/rust/frb_generated.dart';

Future<void> main() async {
  logger.info('Starting Xelis Mobile Wallet ...');
  initFlutterLogging();
  logger.info('initializing Flutter bindings ...');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  logger.info('initializing Rust lib ...');
  await RustLib.init();
  await initRustLogging();

  //-------------------------- PRELOAD ASSETS ----------------------------------
  AppResources.svgBannerGreen = await ScalableImage.fromSvgAsset(
      rootBundle, AppResources.svgBannerGreenPath,
      compact: true);
  AppResources.svgBannerBlack = await ScalableImage.fromSvgAsset(
      rootBundle, AppResources.svgBannerBlackPath,
      compact: true);
  AppResources.svgBannerWhite = await ScalableImage.fromSvgAsset(
      rootBundle, AppResources.svgBannerWhitePath,
      compact: true);
  //----------------------------------------------------------------------------

  final prefs = await SharedPreferences.getInstance();

  logger.info('initialisation done!');
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      observers: kDebugMode ? [LoggerProviderObserver()] : null,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _lightTheme = FlexTheme().light();
  final _darkTheme = FlexTheme().dark();

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final userThemeMode = ref.watch(userThemeModeProvider);
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);

    return WalletInitializerWidget(
      child: GlobalLoaderOverlay(
        useDefaultLoading: false,
        overlayWidgetBuilder: (_) {
          Color loadingWidgetColor;
          switch (userThemeMode.themeMode) {
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
          }
          return Center(
              child: CircularProgressIndicator(
            color: loadingWidgetColor,
          ));
        },
        child: MaterialApp.router(
          title: 'Xelis Wallet',
          scaffoldMessengerKey: scaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          themeMode: userThemeMode.themeMode,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
