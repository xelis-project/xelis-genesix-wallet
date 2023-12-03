import 'package:isar/isar.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';

class StorageManager {
  StorageManager(this.isar, this.walletId);

  final Isar isar;
  final int walletId;

  Stream<WalletSnapshot> watchDB() async* {
    final newWalletSnapshot =
        isar.walletSnapshots.watchObject(walletId, fireImmediately: true);
    await for (final snapshot in newWalletSnapshot) {
      if (snapshot != null) {
        yield snapshot;
      }
    }
  }

  Stream<String> watchWalletName() async* {
    final wallet = await isar.walletSnapshots.get(walletId);
    if (wallet != null) {
      final walletName = wallet.name;
      if (walletName != null) yield walletName;
    }
  }

  Stream<String> watchWalletAddress() async* {
    final wallet = await isar.walletSnapshots.get(walletId);
    if (wallet != null) {
      final address = wallet.address;
      if (address != null) yield address;
    }
  }

  Stream<int> watchWalletTopoHeight() async* {
    final query = isar.walletSnapshots
        .where()
        .idEqualTo(walletId)
        .syncedTopoheightProperty()
        .build();

    await for (final results in query.watch(fireImmediately: true)) {
      if (results.first != null) {
        yield results.first!;
      }
    }
  }

  Stream<List<AssetEntry>> watchWalletAssets() async* {
    final query =
        isar.assetEntrys.filter().wallet((q) => q.idEqualTo(walletId)).build();

    await for (final results in query.watch(fireImmediately: true)) {
      yield results;
    }
  }

  Stream<List<TransactionEntry>> watchWalletHistory() async* {
    final history = isar.transactionEntrys
        .filter()
        .wallet((q) => q.idEqualTo(walletId))
        .sortByTopoHeightDesc()
        .build();

    await for (final results in history.watch(fireImmediately: true)) {
      yield results;
    }
  }

  Stream<VersionedBalance> watchAssetLastBalance(String assetHash) async* {
    final assetQuery = isar.assetEntrys
        .filter()
        .wallet((q) => q.idEqualTo(walletId))
        .hashEqualTo(assetHash)
        .build();

    await for (final assets in assetQuery.watch(fireImmediately: true)) {
      if (assets.isNotEmpty) {
        final balanceQuery =
            assets.first.balance.filter().sortByTopoHeightDesc().build();
        await for (final results in balanceQuery.watch(fireImmediately: true)) {
          if (results.isNotEmpty) {
            yield results.first;
          }
        }
      } else {
        yield VersionedBalance();
      }
    }
  }

  Future<void> saveWalletSnapshot(WalletSnapshot walletSnapshot) async {
    await isar.writeTxn(() async => isar.walletSnapshots.put(walletSnapshot));
  }

  Future<WalletSnapshot?> getWalletSnapshot() async {
    return isar.walletSnapshots.get(walletId);
  }

  Future<VersionedBalance?> getLastBalance(String assetHash) async {
    final snapshot = await getWalletSnapshot();
    if (snapshot != null) {
      final asset =
          await snapshot.assets.filter().hashEqualTo(assetHash).findFirst();
      final versionedBalance =
          asset?.balance.filter().sortByTopoHeight().findFirst();
      return versionedBalance;
    }
    return null;
  }

  Future<AddressBookEntry?> getAddressBookEntry(String name) async {
    final walletSnapshot = await getWalletSnapshot();
    if (walletSnapshot != null) {
      if (walletSnapshot.addressBook.isNotEmpty) {
        for (final entry in walletSnapshot.addressBook) {
          if (entry.name! == name) {
            return entry;
          }
        }
      }
    }
    return null;
  }

  Future<AssetEntry?> getAsset(String assetHash) async {
    final walletSnapshot = await getWalletSnapshot();
    return walletSnapshot?.assets.filter().hashEqualTo(assetHash).findFirst();
  }

  Future<void> addAsset(AssetEntry newAsset) async {
    final walletSnapshot = await getWalletSnapshot();
    if (walletSnapshot != null) {
      walletSnapshot.assets.add(newAsset);

      await isar.writeTxn(() async {
        await isar.assetEntrys.put(newAsset);
        await walletSnapshot.assets.save();
      });
    }
  }

  // TODO comment
  Future<void> addVersionedBalance(
    String assetHash,
    int balance,
    int topoHeight,
    bool synced,
  ) async {
    final versionedBalance = VersionedBalance()
      ..balance = balance
      ..topoHeight = topoHeight;

    final assetEntry = await getAsset(assetHash);

    if (assetEntry != null) {
      if (topoHeight > assetEntry.lastBalanceTopoheight!) {
        assetEntry.lastBalanceTopoheight = topoHeight;
      } else if (topoHeight < assetEntry.firstBalanceTopoheight!) {
        assetEntry.firstBalanceTopoheight = topoHeight;
      }

      if (synced) assetEntry.syncedSinceBeginning = synced;

      assetEntry.balance.add(versionedBalance);

      await isar.writeTxn(() async {
        await isar.versionedBalances.put(versionedBalance);
        await assetEntry.balance.save();
        await isar.assetEntrys.put(assetEntry);
      });
    } else {
      final newAssetEntry = AssetEntry()
        ..hash = assetHash
        ..lastBalanceTopoheight = topoHeight
        ..firstBalanceTopoheight = topoHeight;

      await addAsset(newAssetEntry);

      newAssetEntry.balance.add(versionedBalance);

      await isar.writeTxn(() async {
        await isar.versionedBalances.put(versionedBalance);
        await newAssetEntry.balance.save();
      });
    }
  }

  Future<void> addTransaction(TransactionEntry newTx) async {
    final walletSnapshot = await getWalletSnapshot();
    if (walletSnapshot != null) {
      walletSnapshot.history.add(newTx);

      await isar.writeTxn(() async {
        await isar.transactionEntrys.put(newTx);
        await walletSnapshot.history.save();
      });
    }
  }

  Future<void> setSyncedTopoHeight(int topoHeight) async {
    final snapshot = await getWalletSnapshot();
    if (snapshot != null) {
      snapshot.syncedTopoheight = topoHeight;
      await saveWalletSnapshot(snapshot);
    }
  }

  Future<void> setNonce(int nonce) async {
    final snapshot = await getWalletSnapshot();
    if (snapshot != null) {
      snapshot.nonce = nonce;
      await saveWalletSnapshot(snapshot);
    }
  }

  Future<void> setAddressBookEntry(AddressBookEntry addressBookEntry) async {
    final walletSnapshot = await getWalletSnapshot();
    if (walletSnapshot != null) {
      final addressBook = walletSnapshot.addressBook;
      for (final entry in addressBook) {
        if (entry.name! == addressBookEntry.name!) {
          addressBook.remove(entry);
          continue;
        }
        addressBook.add(addressBookEntry);
        walletSnapshot.addressBook = addressBook;
        await saveWalletSnapshot(walletSnapshot);
      }
    }
  }

  Future<void> removeAddressBookEntry(String name) async {
    final walletSnapshot = await getWalletSnapshot();
    if (walletSnapshot != null) {
      final addressBook = walletSnapshot.addressBook;
      for (final entry in addressBook) {
        if (entry.name! == name) {
          addressBook.remove(entry);
          walletSnapshot.addressBook = addressBook;
          await saveWalletSnapshot(walletSnapshot);
          return;
        }
      }
    }
  }
}
