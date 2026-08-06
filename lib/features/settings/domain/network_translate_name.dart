import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

String translateNetworkName(AppLocalizations loc, XelisNetwork network) {
  switch (network) {
    case XelisNetwork.devnet:
      return loc.devnet;
    case XelisNetwork.testnet:
      return loc.testnet;
    case XelisNetwork.mainnet:
      return loc.mainnet;
    case XelisNetwork.stagenet:
      return loc.stagenet;
  }
}
