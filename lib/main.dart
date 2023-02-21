import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xelis_wallet_app/features/router/app_router.dart';
import 'package:xelis_wallet_app/ffi.dart';
import 'package:xelis_wallet_app/shared/colors/color_schemes.g.dart';
import 'package:xelis_wallet_app/shared/logger.dart';
import 'package:xelis_wallet_app/shared/providers/providers.dart';
import 'package:xelis_wallet_app/shared/theme/extensions.dart';

Future<void> main() async {
  initLogging();
  final keyPair = await api.createKeyPair();
  final address = await api.getAddress(keyPair: keyPair);
  logger.info('Xelis Address: $address');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Xelis Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        textTheme: context.textTheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        textTheme: context.textTheme,
      ),
      routerConfig: router,
      // routeInformationProvider: router.routeInformationProvider,
      // routeInformationParser: router.routeInformationParser,
      // routerDelegate: router.routerDelegate,
    );
  }
}
