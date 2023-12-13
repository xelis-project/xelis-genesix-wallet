import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/features/authentication/data/secure_storage_repository.dart';
import 'package:xelis_mobile_wallet/features/router/router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/app_themes.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/shared/theme/flex_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload Assets
  AppResources.svgIconGreen = await ScalableImage.fromSvgHttpUrl(
      Uri.parse(AppResources.svgIconGreenTarget),
      compact: true);
  AppResources.svgIconBlack = await ScalableImage.fromSvgHttpUrl(
      Uri.parse(AppResources.svgIconBlackTarget),
      compact: true);
  AppResources.svgIconWhite = await ScalableImage.fromSvgHttpUrl(
      Uri.parse(AppResources.svgIconWhiteTarget),
      compact: true);

  initLogging();
  logger.info('Starting Xelis Mobile Wallet ...');

  final prefs = await SharedPreferences.getInstance();

  /// TODO: to be removed
  // await SecureStorageRepository.deleteAll();
  // await prefs.clear();

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ThemeProvider();
    final router = ref.watch(routerProvider);
    final userThemeMode = ref.watch(userThemeModeProvider);
    return MaterialApp.router(
      title: 'Xelis Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: userThemeMode.themeMode,
      theme: themeProvider.light(),
      darkTheme: themeProvider.dark(),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
