import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/api.dart';
import 'package:genesix/src/generated/rust_bridge/frb_generated.dart';
import 'package:intl/intl.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:window_manager/window_manager.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:genesix/shared/widgets/genesix_app.dart';
import 'package:localstorage/localstorage.dart';

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
  } else {
    // need to call this before any tls calls
    talker.info('initializing crypto provider ...');
    await initializeCryptoProvider();
  }

  if (isDesktopDevice) {
    talker.info('initializing window manager ...');
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: AppResources.xelisWalletName,
      size: Size(1024, 728),
      minimumSize: Size(400, 600),
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
  AppResources.svgGenesixWalletOneLineWhite = await ScalableImage.fromSvgAsset(
    rootBundle,
    AppResources.genesixWalletOneLineWhitePath,
    // compact: true,
  );
  AppResources.svgGenesixWalletOneLineBlack = await ScalableImage.fromSvgAsset(
    rootBundle,
    AppResources.genesixWalletOneLineBlackPath,
    // compact: true,
  );
  //----------------------------------------------------------------------------

  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  Intl.defaultLocale = locale.toLanguageTag();

  final prefs = await GenesixSharedPreferences.setUp();

  talker.info('initialisation done!');
  FlutterNativeSplash.remove();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      observers: riverpodObserversMinimal(),
      child: const Genesix(),
    ),
  );
}
