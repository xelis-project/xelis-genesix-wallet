import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/router/app_router.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/theme/app_themes.dart';
import 'package:xelis_mobile_wallet/shared/theme/theme_mode.dart';

void main() {
  initLogging();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    final themeProvider = ThemeProvider();
    /*return themeMode.when(
      data: (data) => MaterialApp.router(
        title: 'Xelis Wallet',
        debugShowCheckedModeBanner: false,
        themeMode: data,
        theme: themeProvider.light(context),
        darkTheme: themeProvider.dark(context),
        routerConfig: router,
      ),
      error: (err, stack) => Text('Error: $err'),
      loading: () => const CircularProgressIndicator(),
    );*/
    return MaterialApp.router(
      title: 'Xelis Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: themeProvider.light(context),
      darkTheme: themeProvider.dark(context),
      routerConfig: router,
      // routeInformationProvider: router.routeInformationProvider,
      // routeInformationParser: router.routeInformationParser,
      // routerDelegate: router.routerDelegate,
    );
  }
}
