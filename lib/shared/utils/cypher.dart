import 'package:cryptography/cryptography.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';

Future<SecretKey> newSecretKey() async {
  final cipher = FlutterChacha20.poly1305Aead();
  final secretKey = await cipher.newSecretKey();
  return secretKey;
}

Future<List<int>> encrypt(List<int> bytesSecretKey, String data) async {
  final cipher = FlutterChacha20.poly1305Aead();
  final secretKey = await cipher.newSecretKeyFromBytes(bytesSecretKey);
  final wand = await cipher.newCipherWandFromSecretKey(secretKey);
  final secretBox = await wand.encryptString(data);
  return secretBox.concatenation();
}

Future<String> decrypt(
  List<int> bytesSecretKey,
  List<int> encryptedData,
) async {
  final cipher = FlutterChacha20.poly1305Aead();
  final secretBox = SecretBox.fromConcatenation(
    encryptedData,
    nonceLength: cipher.nonceLength,
    macLength: cipher.macAlgorithm.macLength,
  );
  final secretKey = await cipher.newSecretKeyFromBytes(bytesSecretKey);
  final wand = await cipher.newCipherWandFromSecretKey(secretKey);
  final data = await wand.decryptString(secretBox);
  return data;
}
