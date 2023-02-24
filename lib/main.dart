import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xelis_mobile_wallet/features/router/app_router.dart';
import 'package:xelis_mobile_wallet/ffi.dart';
import 'package:xelis_mobile_wallet/shared/colors/color_schemes.g.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/providers/providers.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

Future<void> main() async {
  initLogging();
  // final wallet = await api.newWallet(name: 'name', password: 'password');
  // final address = await api.getAddress(wallet: wallet);
  // logger.info('Xelis Address: $address');
  // wallet.dispose();
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
