import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/shared/lifecycle/desktop_shutdown_coordinator.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:genesix/features/authentication/application/wallet_session_commands_provider.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/resources/localizations.dart';
import 'package:genesix/shared/widgets/app_initializer.dart';

class Genesix extends ConsumerStatefulWidget {
  const Genesix({super.key});

  @override
  ConsumerState<Genesix> createState() => _GenesixState();
}

class _GenesixState extends ConsumerState<Genesix> with WindowListener {
  late final DesktopShutdownCoordinator _shutdownCoordinator;

  @override
  void initState() {
    super.initState();
    _shutdownCoordinator = DesktopShutdownCoordinator(
      closeSession: _closeWalletSession,
      stopLogging: disposeRustLogging,
      destroyWindow: windowManager.destroy,
      allowNativeClose: _allowNativeClose,
      requestNativeClose: windowManager.close,
      recordFailure: _recordShutdownFailure,
    );
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final appTheme = ref.watch(
      settingsProvider.select((state) => state.appTheme),
    );

    FThemeData themeData;
    final touch = switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.fuchsia => true,
      _ => false,
    };

    switch (appTheme) {
      case AppTheme.light:
        themeData = greenLight(touch: touch);
      case AppTheme.dark:
        themeData = greenDark(touch: touch);
      case AppTheme.xelis:
        themeData = greenDark(touch: touch);
    }

    return MaterialApp.router(
      title: AppResources.xelisWalletName,
      debugShowCheckedModeBanner: false,
      // themeMode: ThemeMode.light,
      theme: themeData.toApproximateMaterialTheme(),
      routerConfig: router,
      localizationsDelegates: genesixLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return GenesixTheme(
          data: themeData,
          child: AppInitializer(child: child!),
        );
      },
    );
  }

  @override
  void onWindowClose() {
    unawaited(_shutdownCoordinator.close());
  }

  Future<void> _closeWalletSession() async {
    await ref.read(walletSessionCommandsProvider.notifier).logout();
  }

  Future<void> _allowNativeClose() {
    return windowManager.setPreventClose(false);
  }

  void _recordShutdownFailure(
    String phase,
    Object error,
    StackTrace stackTrace,
  ) {
    logSupportEvent(
      AppSupportEvent.desktopShutdownFailed,
      diagnosticContext: 'phase=$phase errorType=${error.runtimeType}',
      stackTrace: stackTrace,
    );
  }
}
