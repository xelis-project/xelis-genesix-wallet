import 'dart:io';

import 'package:genesix/features/logger/logger.dart';
import 'package:local_auth/local_auth.dart';
import 'package:window_manager/window_manager.dart';

class BiometricAuthRepository {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> get canCheckBiometrics => auth.canCheckBiometrics;

  Future<bool> canAuthenticate() async {
    try {
      if (!await auth.isDeviceSupported()) {
        return false;
      }
    } catch (e) {
      talker.error('Local_Auth - isDeviceSupported error: $e');
      return false;
    }

    final List<BiometricType> availableBiometrics = await auth
        .getAvailableBiometrics();
    talker.debug('Local_Auth - availableBiometrics: $availableBiometrics');
    final canCheckBiometrics = await auth.canCheckBiometrics;
    talker.debug('Local_Auth - canCheckBiometrics: $canCheckBiometrics');
    final isDeviceSupported = await auth.isDeviceSupported();
    talker.debug('Local_Auth - isDeviceSupported: $isDeviceSupported');
    return canCheckBiometrics || isDeviceSupported;
  }

  Future<bool> authenticate(String reason) async {
    final res = await auth.authenticate(
      localizedReason: reason,
      options: AuthenticationOptions(
        biometricOnly: Platform.isWindows ? false : true,
      ),
    );

    // this is needed to fix issue with local_auth on Windows
    // see https://github.com/flutter/flutter/issues/122322
    if (Platform.isWindows) {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.blur();
      await windowManager.show();
      await windowManager.setAlwaysOnTop(false);
    }

    return res;
  }

  Future<void> stopAuthentication() async {
    await auth.stopAuthentication();
  }
}
