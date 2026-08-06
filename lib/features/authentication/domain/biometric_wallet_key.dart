import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

String biometricWalletKey({
  required XelisNetwork network,
  required String walletName,
}) {
  return 'biometric_auth:${network.name}:$walletName';
}

String walletPasswordKey({
  required XelisNetwork network,
  required String walletName,
}) {
  return 'wallet_password:${network.name}:$walletName';
}

String legacyWalletPasswordKey({required String walletName}) {
  return walletName;
}
