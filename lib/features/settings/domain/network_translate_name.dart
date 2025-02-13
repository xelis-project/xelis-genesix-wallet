import 'package:genesix/src/generated/rust_bridge/api/network.dart';

String translateNetworkName(Network network) {
  switch (network) {
    case Network.dev:
      return 'Dev';
    case Network.testnet:
      return 'Testnet';
    case Network.mainnet:
      return 'Mainnet';
  }
}
