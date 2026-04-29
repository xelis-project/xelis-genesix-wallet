import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';

String biometricWalletKey({
  required Network network,
  required String walletName,
}) {
  return 'biometric_auth:${network.name}:$walletName';
}
