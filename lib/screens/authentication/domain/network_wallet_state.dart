// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_mobile_wallet/rust_bridge/api/wallet.dart';

part 'network_wallet_state.freezed.dart';
part 'network_wallet_state.g.dart';

@freezed
class NetworkWalletState with _$NetworkWalletState {
  const NetworkWalletState._(); // https://pub.dev/packages/freezed#adding-getters-and-methods-to-our-models

  const factory NetworkWalletState({
    @JsonKey(name: 'open_mainnet') String? openMainnet,
    @JsonKey(name: 'mainnet_wallets')
    @Default({})
    Map<String, String> mainnetWallets,
    @JsonKey(name: 'open_testnet') String? openTestnet,
    @JsonKey(name: 'testnet_wallets')
    @Default({})
    Map<String, String> testnetWallets,
    @JsonKey(name: 'open_dev') String? openDev,
    @JsonKey(name: 'dev_wallets') @Default({}) Map<String, String> devWallets,
  }) = _NetworkWalletState;

  String? getOpenWallet(Network network) {
    switch (network) {
      case Network.mainnet:
        return openMainnet;
      case Network.testnet:
        return openTestnet;
      case Network.dev:
        return openDev;
    }
  }

  Map<String, String> getWallets(Network network) {
    switch (network) {
      case Network.mainnet:
        return mainnetWallets;
      case Network.testnet:
        return testnetWallets;
      case Network.dev:
        return devWallets;
    }
  }

  factory NetworkWalletState.fromJson(Map<String, dynamic> json) =>
      _$NetworkWalletStateFromJson(json);
}
