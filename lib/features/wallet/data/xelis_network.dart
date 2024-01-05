import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as dart_sdk;
import 'package:xelis_mobile_wallet/src/rust/api/network.dart';

Future<void> setNetwork(dart_sdk.Network network) async {
  switch (network) {
    case dart_sdk.Network.mainnet:
      await setNetworkToMainnet();
    case dart_sdk.Network.testnet:
      await setNetworkToTestnet();
    case dart_sdk.Network.dev:
      await setNetworkToDev();
  }
}
