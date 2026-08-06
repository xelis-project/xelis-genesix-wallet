import 'package:genesix/features/router/extra_type_adapter.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

/// Lossless GoRouter codec for confirmed wallet-history entries.
///
/// Native unsigned integers are encoded as decimal strings. Explicit history
/// payloads remain only on the original object used by an imperative push;
/// this persistent representation keeps only a redacted summary. The native
/// shared encryption key is not part of the package model.
class TransactionEntryAdapter
    extends ExtraTypeAdapter<XelisWalletTransactionEntry> {
  const TransactionEntryAdapter();

  @override
  String get type => 'transaction_entry';

  @override
  Object? encode(XelisWalletTransactionEntry value) => <String, Object?>{
    'schema_version': 1,
    'hash': value.hash,
    'topoheight': value.topoheight.toString(),
    'timestamp_millis': value.timestampMillis.toString(),
    'entry': _encodeEntry(value.entry),
  };

  @override
  XelisWalletTransactionEntry decode(Object? payload) {
    final json = _json(payload, 'transaction entry');
    if (_integer(json['schema_version'], 'schema_version') != 1) {
      throw const FormatException('Unsupported transaction entry schema');
    }

    return XelisWalletTransactionEntry(
      hash: _string(json['hash'], 'hash'),
      topoheight: _bigInt(json['topoheight'], 'topoheight'),
      timestampMillis: _bigInt(json['timestamp_millis'], 'timestamp_millis'),
      entry: _decodeEntry(json['entry']),
    );
  }
}

/// Redacted GoRouter codec for pending wallet entries.
class PendingTransactionEntryAdapter
    extends ExtraTypeAdapter<XelisWalletPendingTransaction> {
  const PendingTransactionEntryAdapter();

  @override
  String get type => 'pending_transaction_entry';

  @override
  Object? encode(XelisWalletPendingTransaction value) => <String, Object?>{
    'schema_version': 1,
    'hash': value.hash,
    'timestamp_millis': value.timestampMillis.toString(),
    'entry': _encodeEntry(value.entry),
  };

  @override
  XelisWalletPendingTransaction decode(Object? payload) {
    final json = _json(payload, 'pending transaction entry');
    if (_integer(json['schema_version'], 'schema_version') != 1) {
      throw const FormatException(
        'Unsupported pending transaction entry schema',
      );
    }

    return XelisWalletPendingTransaction(
      hash: _string(json['hash'], 'hash'),
      timestampMillis: _bigInt(json['timestamp_millis'], 'timestamp_millis'),
      entry: _decodeEntry(json['entry']),
    );
  }
}

Json _encodeEntry(XelisWalletTransactionEntryData entry) => switch (entry) {
  XelisWalletCoinbaseEntry() => <String, Object?>{
    'kind': 'coinbase',
    'reward': entry.reward.toString(),
  },
  XelisWalletBurnEntry() => <String, Object?>{
    'kind': 'burn',
    'asset': entry.asset,
    'amount': entry.amount.toString(),
    'fee': entry.fee.toString(),
    'nonce': entry.nonce.toString(),
  },
  XelisWalletIncomingEntry() => <String, Object?>{
    'kind': 'incoming',
    'from': entry.from,
    'transfers': entry.transfers
        .map(
          (transfer) => <String, Object?>{
            'asset': transfer.asset,
            'amount': transfer.amount.toString(),
            'extra_data': _encodeOptionalExtraData(transfer.extraData),
          },
        )
        .toList(),
  },
  XelisWalletOutgoingEntry() => <String, Object?>{
    'kind': 'outgoing',
    'transfers': entry.transfers
        .map(
          (transfer) => <String, Object?>{
            'destination': transfer.destination,
            'asset': transfer.asset,
            'amount': transfer.amount.toString(),
            'extra_data': _encodeOptionalExtraData(transfer.extraData),
          },
        )
        .toList(),
    'fee': entry.fee.toString(),
    'nonce': entry.nonce.toString(),
  },
  XelisWalletMultisigEntry() => <String, Object?>{
    'kind': 'multisig',
    'participants': entry.participants,
    'threshold': entry.threshold,
    'fee': entry.fee.toString(),
    'nonce': entry.nonce.toString(),
  },
  XelisWalletInvokeContractEntry() => <String, Object?>{
    'kind': 'invoke_contract',
    'contract': entry.contract,
    'deposits': entry.deposits.map(_encodeAssetAmount).toList(),
    'received': entry.received.map(_encodeContractGroup).toList(),
    'chunk_id': entry.chunkId,
    'fee': entry.fee.toString(),
    'max_gas': entry.maxGas.toString(),
    'nonce': entry.nonce.toString(),
  },
  XelisWalletDeployContractEntry() => <String, Object?>{
    'kind': 'deploy_contract',
    'fee': entry.fee.toString(),
    'nonce': entry.nonce.toString(),
    'invoke': entry.invoke == null
        ? null
        : <String, Object?>{
            'max_gas': entry.invoke!.maxGas.toString(),
            'deposits': entry.invoke!.deposits.map(_encodeAssetAmount).toList(),
          },
  },
  XelisWalletIncomingContractEntry() => <String, Object?>{
    'kind': 'incoming_contract',
    'transfers': entry.transfers.map(_encodeContractGroup).toList(),
  },
  XelisWalletOutgoingBlobEntry() => <String, Object?>{
    'kind': 'outgoing_blob',
    'destinations': entry.destinations,
    'fee': entry.fee.toString(),
    'nonce': entry.nonce.toString(),
    'data': _encodeExtraData(entry.data),
  },
  XelisWalletIncomingBlobEntry() => <String, Object?>{
    'kind': 'incoming_blob',
    'from': entry.from,
    'destinations': entry.destinations,
    'data': _encodeExtraData(entry.data),
  },
};

XelisWalletTransactionEntryData _decodeEntry(Object? value) {
  final json = _json(value, 'entry');
  return switch (_string(json['kind'], 'entry.kind')) {
    'coinbase' => XelisWalletCoinbaseEntry(
      reward: _bigInt(json['reward'], 'entry.reward'),
    ),
    'burn' => XelisWalletBurnEntry(
      asset: _string(json['asset'], 'entry.asset'),
      amount: _bigInt(json['amount'], 'entry.amount'),
      fee: _bigInt(json['fee'], 'entry.fee'),
      nonce: _bigInt(json['nonce'], 'entry.nonce'),
    ),
    'incoming' => XelisWalletIncomingEntry(
      from: _string(json['from'], 'entry.from'),
      transfers: _list(json['transfers'], 'entry.transfers').map((value) {
        final transfer = _json(value, 'incoming transfer');
        return XelisWalletTransferIn(
          asset: _string(transfer['asset'], 'transfer.asset'),
          amount: _bigInt(transfer['amount'], 'transfer.amount'),
          extraData: _decodeOptionalExtraData(transfer['extra_data']),
        );
      }).toList(),
    ),
    'outgoing' => XelisWalletOutgoingEntry(
      transfers: _list(json['transfers'], 'entry.transfers').map((value) {
        final transfer = _json(value, 'outgoing transfer');
        return XelisWalletTransferOut(
          destination: _string(transfer['destination'], 'transfer.destination'),
          asset: _string(transfer['asset'], 'transfer.asset'),
          amount: _bigInt(transfer['amount'], 'transfer.amount'),
          extraData: _decodeOptionalExtraData(transfer['extra_data']),
        );
      }).toList(),
      fee: _bigInt(json['fee'], 'entry.fee'),
      nonce: _bigInt(json['nonce'], 'entry.nonce'),
    ),
    'multisig' => XelisWalletMultisigEntry(
      participants: _list(
        json['participants'],
        'entry.participants',
      ).map((value) => _string(value, 'participant')).toList(),
      threshold: _integer(json['threshold'], 'entry.threshold'),
      fee: _bigInt(json['fee'], 'entry.fee'),
      nonce: _bigInt(json['nonce'], 'entry.nonce'),
    ),
    'invoke_contract' => XelisWalletInvokeContractEntry(
      contract: _string(json['contract'], 'entry.contract'),
      deposits: _decodeAssetAmounts(json['deposits'], 'entry.deposits'),
      received: _decodeContractGroups(json['received'], 'entry.received'),
      chunkId: _integer(json['chunk_id'], 'entry.chunk_id'),
      fee: _bigInt(json['fee'], 'entry.fee'),
      maxGas: _bigInt(json['max_gas'], 'entry.max_gas'),
      nonce: _bigInt(json['nonce'], 'entry.nonce'),
    ),
    'deploy_contract' => XelisWalletDeployContractEntry(
      fee: _bigInt(json['fee'], 'entry.fee'),
      nonce: _bigInt(json['nonce'], 'entry.nonce'),
      invoke: _decodeDeployInvoke(json['invoke']),
    ),
    'incoming_contract' => XelisWalletIncomingContractEntry(
      transfers: _decodeContractGroups(json['transfers'], 'entry.transfers'),
    ),
    'outgoing_blob' => XelisWalletOutgoingBlobEntry(
      destinations: _decodeStrings(json['destinations'], 'entry.destinations'),
      fee: _bigInt(json['fee'], 'entry.fee'),
      nonce: _bigInt(json['nonce'], 'entry.nonce'),
      data: _decodeExtraData(json['data']),
    ),
    'incoming_blob' => XelisWalletIncomingBlobEntry(
      from: _string(json['from'], 'entry.from'),
      destinations: _decodeStrings(json['destinations'], 'entry.destinations'),
      data: _decodeExtraData(json['data']),
    ),
    final kind => throw FormatException(
      'Unknown transaction entry kind: $kind',
    ),
  };
}

Object? _encodeOptionalExtraData(XelisWalletExtraData? value) =>
    value == null ? null : _encodeExtraData(value);

Json _encodeExtraData(XelisWalletExtraData value) => <String, Object?>{
  // GoRouter persists this codec output for restoration. Keep only the
  // non-sensitive summary; an imperative push retains the original object in
  // memory for the currently displayed detail page.
  'flag': value.flag.name,
  'has_payload': value.hasPayload,
};

XelisWalletExtraData? _decodeOptionalExtraData(Object? value) {
  if (value == null) return null;
  return _decodeExtraData(value);
}

XelisWalletExtraData _decodeExtraData(Object? value) {
  final json = _json(value, 'extra_data');
  return XelisWalletExtraData(
    flag: XelisWalletExtraDataFlag.values.byName(
      _string(json['flag'], 'extra_data.flag'),
    ),
    hasPayload: _boolean(json['has_payload'], 'extra_data.has_payload'),
    // Never restore an explicit payload from serialized navigation state,
    // including state written by an older application version.
    payload: null,
    payloadKind: null,
  );
}

Json _encodeAssetAmount(XelisWalletAssetAmount value) => <String, Object?>{
  'asset': value.asset,
  'amount': value.amount.toString(),
};

List<XelisWalletAssetAmount> _decodeAssetAmounts(Object? value, String field) =>
    _list(value, field).map((value) {
      final amount = _json(value, 'asset amount');
      return XelisWalletAssetAmount(
        asset: _string(amount['asset'], 'asset amount.asset'),
        amount: _bigInt(amount['amount'], 'asset amount.amount'),
      );
    }).toList();

Json _encodeContractGroup(XelisWalletContractTransferGroup value) =>
    <String, Object?>{
      'contract': value.contract,
      'transfers': value.transfers.map(_encodeAssetAmount).toList(),
    };

List<XelisWalletContractTransferGroup> _decodeContractGroups(
  Object? value,
  String field,
) => _list(value, field).map((value) {
  final group = _json(value, 'contract transfer group');
  return XelisWalletContractTransferGroup(
    contract: _string(group['contract'], 'contract transfer group.contract'),
    transfers: _decodeAssetAmounts(
      group['transfers'],
      'contract transfer group.transfers',
    ),
  );
}).toList();

XelisWalletDeployInvoke? _decodeDeployInvoke(Object? value) {
  if (value == null) return null;
  final invoke = _json(value, 'deploy invoke');
  return XelisWalletDeployInvoke(
    maxGas: _bigInt(invoke['max_gas'], 'deploy invoke.max_gas'),
    deposits: _decodeAssetAmounts(invoke['deposits'], 'deploy invoke.deposits'),
  );
}

List<String> _decodeStrings(Object? value, String field) =>
    _list(value, field).map((value) => _string(value, field)).toList();

Json _json(Object? value, String field) {
  if (value is! Map) throw FormatException('$field must be an object');
  return Map<String, dynamic>.from(value);
}

List<Object?> _list(Object? value, String field) {
  if (value is! List) throw FormatException('$field must be a list');
  return List<Object?>.from(value);
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string');
  return value;
}

BigInt _bigInt(Object? value, String field) {
  final encoded = _string(value, field);
  final decoded = BigInt.tryParse(encoded);
  if (decoded == null) throw FormatException('$field must be an integer');
  return decoded;
}

int _integer(Object? value, String field) {
  if (value is! int) throw FormatException('$field must be an integer');
  return value;
}

bool _boolean(Object? value, String field) {
  if (value is! bool) throw FormatException('$field must be a boolean');
  return value;
}
