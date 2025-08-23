import 'dart:convert';

import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

typedef Json = Map<String, dynamic>;

class ExtraCodec extends Codec<Object?, Object?> {
  const ExtraCodec();

  @override
  Converter<Object?, Object?> get encoder => _TransactionEntryEncoder();

  @override
  Converter<Object?, Object?> get decoder => _TransactionEntryDecoder();
}

class _TransactionEntryEncoder extends Converter<Object?, Object?> {
  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }
    switch (input) {
      case TransactionEntry _:
        final (key, entryTypeJson) = switch (input.txEntryType) {
          CoinbaseEntry e => ('coinbase', e.toJson()),
          BurnEntry e => ('burn', e.toJson()),
          IncomingEntry e => ('incoming', e.toJson()),
          OutgoingEntry e => ('outgoing', e.toJson()),
          MultisigEntry e => ('multi_sig', e.toJson()),
          InvokeContractEntry e => ('invoke_contract', e.toJson()),
          DeployContractEntry e => ('deploy_contract', e.toJson()),
        };

        final Json payload = {
          'hash': input.hash,
          'topoheight': input.topoheight,
          'timestamp': input.timestamp?.millisecondsSinceEpoch,
          key: entryTypeJson,
        };

        return <Object?>['TransactionEntry', payload];
      default:
        throw FormatException('Cannot encode type ${input.runtimeType}');
    }
  }
}

class _TransactionEntryDecoder extends Converter<Object?, Object?> {
  @override
  Object? convert(Object? input) {
    if (input == null) {
      return null;
    }

    final List<Object?> inputAsList = input as List<Object?>;

    if (inputAsList[0] == 'TransactionEntry') {
      return TransactionEntry.fromJson(inputAsList[1] as Json);
    }

    throw FormatException('Unable to parse input: $input');
  }
}
