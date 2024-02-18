import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  initFlutterLogging();
  logger.info('Starting Xelis Mobile Wallet ...');
  logger.info('initializing Rust lib ...');
  await RustLib.init();
  await initRustLogging();
  logger.info('initializing Flutter bindings ...');
  WidgetsFlutterBinding.ensureInitialized();
  logger.info('initialisation done!');

  //-------------------------- PRELOAD ASSETS ----------------------------------
  // AppResources.svgIconGreen = await ScalableImage.fromSvgHttpUrl(
  //     Uri.parse(AppResources.svgIconGreenTarget),
  //     compact: true);
  // AppResources.svgIconBlack = await ScalableImage.fromSvgHttpUrl(
  //     Uri.parse(AppResources.svgIconBlackTarget),
  //     compact: true);
  // AppResources.svgIconWhite = await ScalableImage.fromSvgHttpUrl(
  //     Uri.parse(AppResources.svgIconWhiteTarget),
  //     compact: true);

  AppResources.svgBannerGreen = await ScalableImage.fromSvgHttpUrl(
      Uri.parse(AppResources.svgBannerGreenTarget),
      compact: true);
  AppResources.svgBannerBlack = await ScalableImage.fromSvgHttpUrl(
      Uri.parse(AppResources.svgBannerBlackTarget),
      compact: true);
  AppResources.svgBannerWhite = await ScalableImage.fromSvgHttpUrl(
      Uri.parse(AppResources.svgBannerWhiteTarget),
      compact: true);
  //----------------------------------------------------------------------------

  final prefs = await SharedPreferences.getInstance();

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
