import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/authentication/data/secure_storage_repository.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/account.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/authentication_state.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/daemon_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/isar/isar_provider.dart';
import 'package:xelis_mobile_wallet/shared/utils/cypher.dart';

part 'authentication_service.g.dart';

@riverpod
class Authentication extends _$Authentication {
  @override
  AuthenticationState build() {
    return const AuthenticationState.signedOut();
  }

  Future<void> createWallet(
    String name,
    String password, [
    String? seed,
  ]) async {
    if (await SecureStorageRepository.contain(key: 'xelis_$name')) {
      logger.warning(
        'A wallet with this name already exists : $name',
      );
      return;
    }
    final secretKey = await newSecretKey();
    final bytesSecretKey = await secretKey.extractBytes();
    final account =
        Account(name: name, password: password, secretKey: bytesSecretKey);

    await SecureStorageRepository.save(
      key: 'xelis_$name',
      value: account.toJson(),
    );

    final walletEntry = WalletSnapshot()..name = name;

    if (seed != null) {
      final encryptedSeed = await encrypt(bytesSecretKey, seed);
      walletEntry
        ..encryptedSeed = encryptedSeed
        ..imported = true;
    } else {
      final newSeed = await NativeWalletRepository.generateNewSeed();
      final encryptedSeed = await encrypt(bytesSecretKey, newSeed);
      walletEntry.encryptedSeed = encryptedSeed;
    }

    final isar = await ref.read(isarPodProvider.future);
    final wallets = isar.walletSnapshots;
    await isar.writeTxn(() async => wallets.put(walletEntry));

    await SecureStorageRepository.save(
      key: 'xelis_wallet_currently_used',
      value: account.toJson(),
    );

    state = AuthenticationState.signedIn(
      walletId: walletEntry.id,
      secretKey: bytesSecretKey,
    );
  }

  Future<void> openWallet(String name, String password) async {
    final data = await SecureStorageRepository.get(key: 'xelis_$name');
    if (data == null) {
      logger.warning(
        'This key does not exist in secure storage: $name',
      );
      return;
    }

    final account = Account.fromJson(data as Map<String, dynamic>);
    if (password == account.password) {
      final isar = await ref.read(isarPodProvider.future);
      final wallet = await isar.walletSnapshots.getByName(name);
      if (wallet == null) {
        logger.warning(
          'Wallet not found in Isar db: $name',
        );
        return;
      }

      await SecureStorageRepository.save(
        key: 'xelis_wallet_currently_used',
        value: account.toJson(),
      );

      state = AuthenticationState.signedIn(
        walletId: wallet.id,
        secretKey: account.secretKey,
      );
    }
  }

  Future<String> getWalletNameCurrentlyUsed() async {
    final data =
        await SecureStorageRepository.get(key: 'xelis_wallet_currently_used');
    if (data == null) {
      logger.warning(
        'This key does not exist in secure storage: xelis_wallet_currently_used',
      );
      return '';
    }

    final account = Account.fromJson(data as Map<String, dynamic>);

    return account.name;
  }

  void logout() {
    state = const AuthenticationState.signedOut();
    ref.read(daemonClientRepositoryPodProvider).disconnect();
  }
}

@riverpod
Future<Map<String, dynamic>> openWalletData(OpenWalletDataRef ref) async {
  List<WalletSnapshot> walletSnapshots =
      await ref.watch(walletSnapshotsProvider.future);
  String walletCurrentlyUsed = await ref
      .watch(authenticationProvider.notifier)
      .getWalletNameCurrentlyUsed();
  return {
    'walletSnapshots': walletSnapshots,
    'walletCurrentlyUsed': walletCurrentlyUsed
  };
}
