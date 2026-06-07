import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/node_info_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;

part 'network_mismatch_provider.g.dart';

@riverpod
bool networkMismatch(Ref ref) {
  final walletNetwork = ref.watch(
    settingsProvider.select((state) => state.network),
  );
  final nodeNetwork = ref.watch(
    nodeInfoProvider.select((state) => state.value?.network),
  );

  bool mismatch = false;
  switch (nodeNetwork) {
    case sdk.Network.mainnet:
      if (walletNetwork != rust.Network.mainnet) {
        mismatch = true;
      }
    case sdk.Network.testnet:
      if (walletNetwork != rust.Network.testnet) {
        mismatch = true;
      }
    case sdk.Network.devnet:
      if (walletNetwork != rust.Network.devnet) {
        mismatch = true;
      }
    case sdk.Network.stagenet:
      if (walletNetwork != rust.Network.stagenet) {
        mismatch = true;
      }
    case null:
      mismatch = false;
  }

  return mismatch;
}
