import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';
import 'package:genesix/src/generated/rust_bridge/frb_generated.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:window_manager/window_manager.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/genesix_app.dart';
import 'package:localstorage/localstorage.dart';
// import 'package:jovial_svg/jovial_svg.dart';

Future<void> main() async {
  talker.info('Starting Genesix...');
  talker.info('initializing Flutter bindings ...');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  talker.info('initializing Rust lib ...');
  await RustLib.init();
  await initRustLogging();

  if (kIsWeb) {
    talker.info('initializing local storage ...');
    await initLocalStorage();
  }

  if (isDesktopDevice) {
    talker.info('initializing window manager ...');
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: AppResources.xelisWalletName,
      size: Size(500, 700),
      minimumSize: Size(400, 600),
      //maximumSize: Size(1000, 1200),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  talker.info('loading assets ...');
  //-------------------------- PRELOAD ASSETS ----------------------------------
  // AppResources.svgBannerGreen = await ScalableImage.fromSvgAsset(
  //     rootBundle, AppResources.svgBannerGreenPath,
  //     compact: true);
  // AppResources.svgBannerBlack = await ScalableImage.fromSvgAsset(
  //     rootBundle, AppResources.svgBannerBlackPath,
  //     compact: true);
  // AppResources.svgBannerWhite = await ScalableImage.fromSvgAsset(
  //     rootBundle, AppResources.svgBannerWhitePath,
  //     compact: true);

  AppResources.bgDots = Image.asset(AppResources.bgDotsPath);
  //----------------------------------------------------------------------------

  final prefs = await GenesixSharedPreferences.setUp();

  talker.info('initialisation done!');
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      observers: [
        TalkerRiverpodObserver(
          talker: talker,
          settings: const TalkerRiverpodLoggerSettings(
            printProviderDisposed: true,
            printStateFullData: kDebugMode ? true : false,
          ),
        ),
      ],
      child: const Genesix(),
    ),
  );
}
