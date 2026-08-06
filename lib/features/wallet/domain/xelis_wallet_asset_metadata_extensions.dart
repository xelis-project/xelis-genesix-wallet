import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

extension XelisWalletMaxSupplyAmount on XelisWalletMaxSupply {
  BigInt? get amountOrNull => switch (this) {
    XelisWalletNoMaxSupply() => null,
    XelisWalletFixedMaxSupply(:final amount) => amount,
    XelisWalletMintableMaxSupply(:final amount) => amount,
  };
}

extension XelisWalletAssetOwnerDetails on XelisWalletAssetOwner {
  String? get originContractOrNull => switch (this) {
    XelisWalletNoAssetOwner() => null,
    XelisWalletAssetCreator(:final contract) => contract,
    XelisWalletCurrentAssetOwner(:final origin) => origin,
  };

  BigInt? get originIdOrNull => switch (this) {
    XelisWalletNoAssetOwner() => null,
    XelisWalletAssetCreator(:final id) => id,
    XelisWalletCurrentAssetOwner(:final originId) => originId,
  };
}
