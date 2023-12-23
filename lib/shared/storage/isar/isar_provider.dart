import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';

part 'isar_provider.g.dart';

@riverpod
Future<Isar> isarPod(IsarPodRef ref) async {
  // final dir = await getApplicationDocumentsDirectory();
  final dir = await getApplicationSupportDirectory();
  final db = await Isar.open(
    [
      WalletSnapshotSchema,
      AssetEntrySchema,
      VersionedBalanceSchema,
      TxEntrySchema,
    ],
    directory: dir.path,
  );
  ref.keepAlive();
  return db;
}

@riverpod
Future<List<String?>> existingWalletNames(ExistingWalletNamesRef ref) async {
  final isar = await ref.watch(isarPodProvider.future);
  final wallets = isar.walletSnapshots;
  return wallets.where().nameProperty().findAll();
}

@riverpod
Future<List<WalletSnapshot>> walletSnapshots(WalletSnapshotsRef ref) async {
  final isar = await ref.watch(isarPodProvider.future);
  final wallets = isar.walletSnapshots;
  return wallets.where().findAll();
}
