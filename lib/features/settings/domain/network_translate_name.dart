import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';

String translateNetworkName(Network network) {
  switch (network) {
    case Network.devnet:
      return 'Devnet';
    case Network.stagenet:
      return 'Stagenet';
    case Network.testnet:
      return 'Testnet';
    case Network.mainnet:
      return 'Mainnet';
  }
}
