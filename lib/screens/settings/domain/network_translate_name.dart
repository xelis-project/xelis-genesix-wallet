import 'package:xelis_mobile_wallet/screens/settings/domain/settings_state.dart';

String translateNetworkName(Network network) {
  switch (network) {
    case Network.dev:
      return 'Dev';
    case Network.testnet:
      return 'Testnet';
    case Network.mainnet:
      return 'Mainnet';
    default:
      return 'N/A';
  }
}
