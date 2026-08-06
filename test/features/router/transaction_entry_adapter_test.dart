import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/router/extra_codec.dart';
import 'package:genesix/features/router/transaction_entry_adapter.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('round-trips non-sensitive fields and redacts explicit payloads', () {
    final huge = BigInt.parse('18446744073709551615');
    const extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.public,
      hasPayload: true,
      payload: XelisDataElement.value(XelisDataValue.string('typed secret')),
      payloadKind: XelisWalletExtraDataPayloadKind.string,
    );
    final entries = <XelisWalletTransactionEntryData>[
      XelisWalletCoinbaseEntry(reward: huge),
      XelisWalletBurnEntry(
        asset: 'asset-burn',
        amount: huge,
        fee: huge,
        nonce: huge,
      ),
      XelisWalletIncomingEntry(
        from: 'address-incoming',
        transfers: [
          XelisWalletTransferIn(
            asset: 'asset-incoming',
            amount: huge,
            extraData: extraData,
          ),
        ],
      ),
      XelisWalletOutgoingEntry(
        transfers: [
          XelisWalletTransferOut(
            destination: 'address-outgoing',
            asset: 'asset-outgoing',
            amount: huge,
            extraData: extraData,
          ),
        ],
        fee: huge,
        nonce: huge,
      ),
      XelisWalletMultisigEntry(
        participants: const ['participant-a', 'participant-b'],
        threshold: 2,
        fee: huge,
        nonce: huge,
      ),
      XelisWalletInvokeContractEntry(
        contract: 'contract-invoke',
        deposits: [XelisWalletAssetAmount(asset: 'asset-a', amount: huge)],
        received: [
          XelisWalletContractTransferGroup(
            contract: 'contract-received',
            transfers: [XelisWalletAssetAmount(asset: 'asset-b', amount: huge)],
          ),
        ],
        chunkId: 7,
        fee: huge,
        maxGas: huge,
        nonce: huge,
      ),
      XelisWalletDeployContractEntry(
        fee: huge,
        nonce: huge,
        invoke: XelisWalletDeployInvoke(
          maxGas: huge,
          deposits: [
            XelisWalletAssetAmount(asset: 'asset-deploy', amount: huge),
          ],
        ),
      ),
      XelisWalletIncomingContractEntry(
        transfers: [
          XelisWalletContractTransferGroup(
            contract: 'contract-incoming',
            transfers: [XelisWalletAssetAmount(asset: 'asset-c', amount: huge)],
          ),
        ],
      ),
      XelisWalletOutgoingBlobEntry(
        destinations: const ['blob-destination'],
        fee: huge,
        nonce: huge,
        data: extraData,
      ),
      XelisWalletIncomingBlobEntry(
        from: 'blob-source',
        destinations: ['blob-destination'],
        data: extraData,
      ),
    ];
    const adapter = TransactionEntryAdapter();

    for (var index = 0; index < entries.length; index++) {
      final transaction = XelisWalletTransactionEntry(
        hash: 'hash-$index',
        topoheight: huge,
        timestampMillis: huge,
        entry: entries[index],
      );
      final encodedJson = jsonEncode(adapter.encode(transaction));

      expect(encodedJson, contains(huge.toString()));
      expect(encodedJson, isNot(contains('payload_json')));
      expect(encodedJson, isNot(contains('payload_kind')));
      expect(encodedJson, isNot(contains('typed secret')));
      expect(encodedJson, isNot(contains('shared_key')));
      expect(encodedJson, isNot(contains('sharedKey')));

      final decoded = adapter.decode(jsonDecode(encodedJson));
      expect(jsonEncode(adapter.encode(decoded)), encodedJson);
      for (final extraData in _entryExtraData(decoded.entry)) {
        expect(extraData.hasPayload, isTrue);
        expect(extraData.payload, isNull);
        expect(extraData.payloadKind, isNull);
      }
    }
  });

  test('drops explicit payload fields from serialized route state', () {
    const adapter = TransactionEntryAdapter();
    final transaction = XelisWalletTransactionEntry(
      hash: 'legacy-hash',
      topoheight: BigInt.one,
      timestampMillis: BigInt.one,
      entry: XelisWalletOutgoingBlobEntry(
        destinations: const ['destination'],
        fee: BigInt.one,
        nonce: BigInt.one,
        data: const XelisWalletExtraData(
          flag: XelisWalletExtraDataFlag.private,
          hasPayload: true,
        ),
      ),
    );
    final encoded = adapter.encode(transaction)! as Map<String, Object?>;
    final entry = encoded['entry']! as Map<String, Object?>;
    final extraData = entry['data']! as Map<String, Object?>;
    extraData['payload_json'] = '{"secret":"legacy-restoration-state"}';
    extraData['payload_kind'] = 'fields';
    extraData['payload'] = <String, Object?>{
      'string': 'legacy-typed-restoration-state',
    };

    final decoded = adapter.decode(encoded);
    final blob = decoded.entry as XelisWalletOutgoingBlobEntry;

    expect(blob.data.hasPayload, isTrue);
    expect(blob.data.payload, isNull);
    expect(blob.data.payloadKind, isNull);
    expect(
      jsonEncode(adapter.encode(decoded)),
      isNot(contains('legacy-restoration-state')),
    );
    expect(
      jsonEncode(adapter.encode(decoded)),
      isNot(contains('legacy-typed-restoration-state')),
    );
  });

  test('round-trips pending metadata while redacting typed payloads', () {
    const adapter = PendingTransactionEntryAdapter();
    const extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.private,
      hasPayload: true,
      payload: XelisDataElement.value(XelisDataValue.string('pending secret')),
    );
    final pending = XelisWalletPendingTransaction(
      hash: 'pending-hash',
      timestampMillis: BigInt.two,
      entry: XelisWalletOutgoingEntry(
        transfers: [
          XelisWalletTransferOut(
            destination: 'xel:pending-destination',
            asset: 'asset',
            amount: BigInt.one,
            extraData: extraData,
          ),
        ],
        fee: BigInt.one,
        nonce: BigInt.one,
      ),
    );

    final encodedJson = jsonEncode(adapter.encode(pending));
    final decoded = adapter.decode(jsonDecode(encodedJson));
    final decodedExtra =
        (decoded.entry as XelisWalletOutgoingEntry).transfers.single.extraData!;

    expect(encodedJson, isNot(contains('pending secret')));
    expect(decoded.hash, pending.hash);
    expect(decoded.timestampMillis, pending.timestampMillis);
    expect(decodedExtra.hasPayload, isTrue);
    expect(decodedExtra.payload, isNull);
  });

  testWidgets('imperative navigation keeps explicit payload only in memory', (
    tester,
  ) async {
    const extraData = XelisWalletExtraData(
      flag: XelisWalletExtraDataFlag.private,
      hasPayload: true,
      payload: XelisDataElement.value(
        XelisDataValue.string('typed display-only'),
      ),
      payloadKind: XelisWalletExtraDataPayloadKind.string,
    );
    final transaction = XelisWalletTransactionEntry(
      hash: 'hash-in-memory',
      topoheight: BigInt.one,
      timestampMillis: BigInt.one,
      entry: XelisWalletOutgoingBlobEntry(
        destinations: const ['destination'],
        fee: BigInt.one,
        nonce: BigInt.one,
        data: extraData,
      ),
    );
    Object? routeExtra;
    final router = GoRouter(
      initialLocation: '/',
      extraCodec: const ExtraCodec(
        adapters: [TransactionEntryAdapter(), PendingTransactionEntryAdapter()],
      ),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Material(
            child: TextButton(
              onPressed: () => context.push('/detail', extra: transaction),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) {
            routeExtra = state.extra;
            return const Material(child: Text('detail'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(routeExtra, same(transaction));
    final inMemoryTransaction = routeExtra! as XelisWalletTransactionEntry;
    final inMemoryBlob =
        inMemoryTransaction.entry as XelisWalletOutgoingBlobEntry;
    expect(inMemoryBlob.data.payload, same(extraData.payload));
    expect(inMemoryBlob.data.payloadKind, extraData.payloadKind);
  });
}

Iterable<XelisWalletExtraData> _entryExtraData(
  XelisWalletTransactionEntryData entry,
) sync* {
  switch (entry) {
    case XelisWalletIncomingEntry():
      for (final transfer in entry.transfers) {
        if (transfer.extraData case final extraData?) yield extraData;
      }
    case XelisWalletOutgoingEntry():
      for (final transfer in entry.transfers) {
        if (transfer.extraData case final extraData?) yield extraData;
      }
    case XelisWalletIncomingBlobEntry():
      yield entry.data;
    case XelisWalletOutgoingBlobEntry():
      yield entry.data;
    default:
      return;
  }
}
