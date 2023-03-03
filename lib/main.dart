import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/features/router/app_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/settings_providers.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/app_themes.dart';

Future<void> main() async {
  initLogging();
  logger.info('Starting Xelis Mobile Wallet ...');

  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  /// TODO: to be removed
  await prefs.clear();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
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
    final isDark = ref.watch(darkModeProvider);
    return MaterialApp.router(
      title: 'Xelis Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: themeProvider.light(context),
      darkTheme: themeProvider.dark(context),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}