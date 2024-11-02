import 'dart:io';

import 'package:local_auth/local_auth.dart';

class BiometricAuthRepository {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> get canCheckBiometrics => auth.canCheckBiometrics;

  Future<bool> canAuthenticate() async {
    final canCheckBiometrics = await auth.canCheckBiometrics;
    return canCheckBiometrics || await auth.isDeviceSupported();
  }

  Future<bool> authenticate(String reason) async {
    return await auth.authenticate(
      localizedReason: reason,
      options: AuthenticationOptions(
        biometricOnly: Platform.isWindows ? false : true,
      ),
    );
  }

  Future<void> stopAuthentication() async {
    await auth.stopAuthentication();
  }
}
