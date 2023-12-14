import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/daemon_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/storage_manager.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_service.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/storage/isar/isar_provider.dart';

part 'wallet_provider.g.dart';

@riverpod
Future<WalletService> walletServicePod(WalletServicePodRef ref) async {
  final secretKey =
      ref.watch(authenticationProvider.select((value) => value.secretKey));
  final daemonClientRepository = ref.watch(daemonClientRepositoryPodProvider);
  final storageManager = await ref.watch(storageManagerPodProvider.future);

  final walletService = WalletService(
    daemonClientRepository,
    storageManager,
    secretKey!,
  );

  if (secretKey.isEmpty) ref.invalidateSelf();

  daemonClientRepository
    ..onOpen(() async {
      // ref.invalidate(daemonInfoProvider);
      await walletService.sync();
    })
    ..onNewBlock((block) async {
      // ref.invalidate(daemonInfoProvider);
      ref.invalidate(lastBlockTimerProvider);

      ref
          .read(nodeInfoProvider.notifier)
          .updateOnNewBlock(block.topoHeight, block.difficulty, block.supply);

      await walletService.sync();
    })
    ..onTransactionAddedInMempool((transaction) async {
      await walletService.sync();
    });

  return walletService;
}

@riverpod
Future<StorageManager> storageManagerPod(StorageManagerPodRef ref) async {
  final isar = await ref.watch(isarPodProvider.future);
  final walletId =
      ref.watch(authenticationProvider.select((value) => value.walletId));

  if (walletId == null) ref.invalidateSelf();

  return StorageManager(isar, walletId!);
}

@riverpod
Stream<String> walletName(WalletNameRef ref) async* {
  final walletService = await ref.watch(walletServicePodProvider.future);
  yield* walletService.storageManager.watchWalletName();
}

@riverpod
Stream<int> walletCurrentTopoHeight(WalletCurrentTopoHeightRef ref) async* {
  final walletService = await ref.watch(walletServicePodProvider.future);
  yield* walletService.storageManager.watchWalletTopoHeight();
}

@riverpod
Stream<String> walletAddress(WalletAddressRef ref) async* {
  final walletService = await ref.watch(walletServicePodProvider.future);
  yield* walletService.storageManager.watchWalletAddress();
}

@riverpod
Stream<VersionedBalance> walletXelisBalance(WalletXelisBalanceRef ref) async* {
  final walletService = await ref.watch(walletServicePodProvider.future);
  yield* walletService.storageManager.watchAssetLastBalance(xelisAsset);
}

@riverpod
Stream<List<TransactionEntry>> walletHistory(WalletHistoryRef ref) async* {
  final walletService = await ref.watch(walletServicePodProvider.future);
  yield* walletService.storageManager.watchWalletHistory();
}

@riverpod
Stream<List<AssetEntry>> walletAssets(WalletAssetsRef ref) async* {
  final walletService = await ref.watch(walletServicePodProvider.future);
  yield* walletService.storageManager.watchWalletAssets();
}

@riverpod
Stream<VersionedBalance> walletAssetLastBalance(
  WalletAssetLastBalanceRef ref, {
  required String hash,
}) async* {
  final walletService = await ref.watch(walletServicePodProvider.future);
  yield* walletService.storageManager.watchAssetLastBalance(hash);
}

@riverpod
Future<String> walletSeed(WalletSeedRef ref) async {
  final walletService = await ref.watch(walletServicePodProvider.future);
  return walletService.getSeed();
}
