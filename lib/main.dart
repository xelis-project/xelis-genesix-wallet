import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xelis_mobile_wallet/features/authentication/data/secure_storage_repository.dart';
import 'package:xelis_mobile_wallet/features/router/router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/app_themes.dart';

import 'ffi.dart';

Future<void> main() async {
  // try {
  // await api.setNetworkToTestnet();
  // await api.setNetworkToDev();
  // await api.setNetworkToMainnet();
  // final xelisKeyPair = await api.createKeyPair();
  //
  // final address = await xelisKeyPair.getAddress();
  //
  // print(address);

  // final xelisKeyPair = await api.createKeyPair(seed: customSeed);

  // final daemonRepository = DaemonClientRepository(endPoint: testnetNodeURL)
  //   ..connect();
  //
  // final nonce = await daemonRepository.getNonce(
  //   const GetNonceParams(
  //     address: myTestnetAddress,
  //   ),
  // );
  // print('nonce : $nonce');

  // final fees = await xelisKeyPair.getEstimatedFees(
  //   address: testAddress,
  //   amount: 100000,
  //   asset: xelisAsset,
  //   nonce: nonce,
  // );
  //
  // print('fees : $fees');
  //
  // final tx = await xelisKeyPair.createTx(
  //   address: testAddress,
  //   amount: 100000,
  //   asset: xelisAsset,
  //   balance: 688402218,
  //   nonce: nonce,
  // );
  //
  // print('tx hex : $tx');
  //
  // final ok = await daemonRepository.submitTransaction(
  //   SubmitTransactionParams(hex: tx),
  // );
  //
  // print('transfer ok : $ok');

  // xelisKeyPair.keyPair.dispose();
  // } catch (e) {
  //   print(e);
  // }

  WidgetsFlutterBinding.ensureInitialized();

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
      theme: themeProvider.light(context),
      darkTheme: themeProvider.dark(context),
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
