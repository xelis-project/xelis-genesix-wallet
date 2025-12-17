import 'package:genesix/features/router/extra_type_adapter.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class TransactionEntryAdapter extends ExtraTypeAdapter<TransactionEntry> {
  const TransactionEntryAdapter();

  @override
  String get type => 'transaction_entry';

  @override
  Object? encode(TransactionEntry value) {
    final (key, entryTypeJson) = switch (value.txEntryType) {
      CoinbaseEntry e => ('coinbase', e.toJson()),
      BurnEntry e => ('burn', e.toJson()),
      IncomingEntry e => ('incoming', e.toJson()),
      OutgoingEntry e => ('outgoing', e.toJson()),
      MultisigEntry e => ('multi_sig', e.toJson()),
      InvokeContractEntry e => ('invoke_contract', e.toJson()),
      DeployContractEntry e => ('deploy_contract', e.toJson()),
    };

    final Json payload = {
      'hash': value.hash,
      'topoheight': value.topoheight,
      'timestamp': value.timestamp?.millisecondsSinceEpoch,
      key: entryTypeJson,
    };

    return payload;
  }

  @override
  TransactionEntry decode(Object? payload) {
    return TransactionEntry.fromJson(payload as Json);
  }
}
