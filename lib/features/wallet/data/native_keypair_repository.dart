import 'package:xelis_mobile_wallet/shared/resources/mnemonics_languages.dart';
import 'package:xelis_mobile_wallet/src/rust/api/keypair.dart';

class NativeKeyPairRepository {
  NativeKeyPairRepository._();

  static Future<String> generateNewSeed() async {
    final xelisKeyPair = await createKeyPair();
    final seed = await xelisKeyPair.getSeed(
      languageIndex: MnemonicsLanguages.english.index,
    );
    // xelisKeyPair.keyPair.dispose();
    return seed;
  }

  static Future<String> getAddress(String seed) async {
    final xelisKeyPair = await createKeyPair(seed: seed);
    final address = await xelisKeyPair.getAddress();
    // xelisKeyPair.keyPair.dispose();
    return address;
  }

  static Future<int> getEstimatedFees(
    String seed,
    String destination,
    int amount,
    String asset,
    int nonce,
  ) async {
    final xelisKeyPair = await createKeyPair(seed: seed);
    final fees = await xelisKeyPair.getEstimatedFees(
      address: destination,
      amount: amount,
      asset: asset,
      nonce: nonce,
    );
    // xelisKeyPair.keyPair.dispose();
    return fees;
  }

  static Future<String> createTransaction(
    String seed,
    String destination,
    int balance,
    int amount,
    String asset,
    int nonce,
  ) async {
    final xelisKeyPair = await createKeyPair(seed: seed);
    final tx = await xelisKeyPair.createTx(
      address: destination,
      amount: amount,
      asset: asset,
      nonce: nonce,
      balance: balance,
    );
    // xelisKeyPair.keyPair.dispose();
    return tx;
  }
}
