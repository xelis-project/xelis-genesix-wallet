import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/domain/xelis_wallet_asset_metadata_extensions.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  group('XelisWalletMaxSupplyAmount', () {
    test('preserves every authored supply variant', () {
      expect(const XelisWalletNoMaxSupply().amountOrNull, isNull);
      expect(
        XelisWalletFixedMaxSupply(amount: BigInt.from(42)).amountOrNull,
        BigInt.from(42),
      );
      expect(
        XelisWalletMintableMaxSupply(amount: BigInt.from(84)).amountOrNull,
        BigInt.from(84),
      );
    });
  });

  group('XelisWalletAssetOwnerDetails', () {
    test('preserves creator and current-owner origins losslessly', () {
      const noOwner = XelisWalletNoAssetOwner();
      expect(noOwner.originContractOrNull, isNull);
      expect(noOwner.originIdOrNull, isNull);

      final creator = XelisWalletAssetCreator(
        contract: 'creator-contract',
        id: BigInt.parse('9007199254740993'),
      );
      expect(creator.originContractOrNull, 'creator-contract');
      expect(creator.originIdOrNull, BigInt.parse('9007199254740993'));

      final currentOwner = XelisWalletCurrentAssetOwner(
        origin: 'origin-contract',
        originId: BigInt.parse('18446744073709551615'),
        owner: 'current-owner',
      );
      expect(currentOwner.originContractOrNull, 'origin-contract');
      expect(currentOwner.originIdOrNull, BigInt.parse('18446744073709551615'));
    });
  });
}
