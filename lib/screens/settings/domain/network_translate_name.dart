import 'dart:ui';

import 'package:xelis_mobile_wallet/screens/settings/domain/network_state.dart';

String translateNetworkName(NetworkType networkType) {
  switch (networkType) {
    case NetworkType.dev:
      return 'Dev';
    case NetworkType.testnet:
      return 'Testnet';
    case NetworkType.mainnet:
      return 'Mainnet';
    default:
      return 'N/A';
  }
}
