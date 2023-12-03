import 'package:isar/isar.dart';

part 'wallet_snapshot.g.dart';

@Collection()
class WalletSnapshot {
  Id id = Isar.autoIncrement;
  @Index(unique: true)
  String? name;
  bool imported = false;
  String? network;
  int? syncedTopoheight;
  String? address;
  int? nonce;
  List<int>? encryptedSeed;
  final assets = IsarLinks<AssetEntry>();
  final history = IsarLinks<TransactionEntry>();

  List<AddressBookEntry> addressBook = <AddressBookEntry>[];

  @override
  String toString() {
    return 'WalletSnapshot{name: $name, imported: $imported, network: $network, syncedTopoheight: $syncedTopoheight, address: $address, nonce: $nonce}';
  }
}

@collection
class AssetEntry {
  Id id = Isar.autoIncrement;
  @Backlink(to: 'assets')
  final wallet = IsarLink<WalletSnapshot>();
  String? hash;
  int? lastBalanceTopoheight;

  int? firstBalanceTopoheight;

  bool syncedSinceBeginning = false;
  final balance = IsarLinks<VersionedBalance>();

  @override
  String toString() {
    return 'AssetEntry{id: $id, hash: $hash, lastBalanceTopoheight: $lastBalanceTopoheight, firstBalanceTopoheight: $firstBalanceTopoheight, syncedSinceBeginning: $syncedSinceBeginning}';
  }
}

@collection
class VersionedBalance {
  Id id = Isar.autoIncrement;
  @Backlink(to: 'balance')
  final asset = IsarLink<AssetEntry>();
  int? balance;
  int? topoHeight;

  @override
  String toString() {
    return '{balance: $balance - topoHeight: $topoHeight}';
  }
}

@collection
class TransactionEntry {
  Id id = Isar.autoIncrement;
  @Backlink(to: 'history')
  final wallet = IsarLink<WalletSnapshot>();
  String? hash;
  String? executedInBlock;
  int? topoHeight;
  int? fees;
  int? nonce;
  EntryData? entryData;
  String? owner;
  String? signature;

  @override
  String toString() {
    return '{hash: $hash - topoheight: $topoHeight '
        '- executedInBlock: $executedInBlock - owner: $owner '
        '- signature: $signature - fees: $fees'
        '- nonce: $nonce - entryData: $entryData}';
  }
}

@embedded
class EntryData {
  int? coinbase;
  BurnEntry? burn;
  OutgoingEntry? outgoing;
  IncomingEntry? incoming;

  @override
  String toString() {
    return '{coinbase: $coinbase - burn: $burn - outgoing: $outgoing - '
        'incoming: $incoming}';
  }

  bool hasData() {
    return coinbase != null ||
        burn != null ||
        outgoing != null ||
        incoming != null;
  }
}

@embedded
class BurnEntry {
  String? asset;
  int? amount;

  @override
  String toString() {
    return '{asset: $asset - amount: $amount}';
  }
}

@embedded
class IncomingEntry {
  String? owner;
  List<TransferEntry> transfers = <TransferEntry>[];

  @override
  String toString() {
    return '{owner: $owner - transfers: $transfers}';
  }
}

@embedded
class OutgoingEntry {
  List<TransferEntry> transfers = <TransferEntry>[];

  @override
  String toString() {
    return '{transfers: $transfers}';
  }
}

@embedded
class TransferEntry {
  String? asset;
  int? amount;
  String? to;
  String? extraData;

  @override
  String toString() {
    return '{asset: $asset - amount: $amount - to: $to '
        '- extraData: $extraData}';
  }
}

@embedded
class AddressBookEntry {
  String? name;
  String? address;

  @override
  String toString() {
    return '{name: $name - address: $address}';
  }
}
