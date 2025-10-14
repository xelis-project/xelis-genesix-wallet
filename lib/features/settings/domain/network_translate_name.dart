import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';

String translateNetworkName(AppLocalizations loc, Network network) {
  switch (network) {
    case Network.devnet:
      return loc.devnet;
    case Network.testnet:
      return loc.testnet;
    case Network.mainnet:
      return loc.mainnet;
    case Network.stagenet:
      return loc.stagenet;
  }
}
