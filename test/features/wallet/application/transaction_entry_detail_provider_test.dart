import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/wallet/application/last_transactions_provider.dart';
import 'package:genesix/features/wallet/application/pending_transactions_provider.dart';
import 'package:genesix/features/wallet/application/transaction_entry_detail_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/transfer_entry_row.dart';
import 'package:genesix/features/wallet/domain/transaction_entry_detail.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('confirmed detail is loaded by hash with detailed disclosure', () async {
    final repository = _FakeNativeWalletRepository(
      confirmed: _confirmedTransaction(
        transfers: [_outgoingTransfer('xel:confirmed', _typedExtraData)],
      ),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    final detail = await container.read(
      transactionEntryDetailProvider((hash: 'confirmed-hash', isPending: false))
          .future,
    );

    expect(detail.hash, 'confirmed-hash');
    expect(detail.isPending, isFalse);
    expect(repository.confirmedHashes, ['confirmed-hash']);
    expect(repository.confirmedDisclosures, [
      XelisWalletExtraDataDisclosure.detailed,
    ]);
    final outgoing = detail.entry as XelisWalletOutgoingEntry;
    expect(outgoing.transfers.single.extraData?.payload, _typedPayload);
  });

  test('pending detail is loaded by hash with detailed disclosure', () async {
    final repository = _FakeNativeWalletRepository(
      pending: _pendingTransaction(
        transfers: [_outgoingTransfer('xel:pending', _typedExtraData)],
      ),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    final detail = await container.read(
      transactionEntryDetailProvider((hash: 'pending-hash', isPending: true))
          .future,
    );

    expect(detail.hash, 'pending-hash');
    expect(detail.isPending, isTrue);
    expect(repository.pendingHashes, ['pending-hash']);
    expect(repository.pendingDetailDisclosures, [
      XelisWalletExtraDataDisclosure.detailed,
    ]);
  });

  test('a detail from a replaced wallet is never published', () async {
    final repositoryA = _FakeNativeWalletRepository();
    final repositoryB = _FakeNativeWalletRepository();
    final gate = Completer<XelisWalletTransactionEntry>();
    repositoryA.nextConfirmed = gate;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'wallet-a', repository: repositoryA));

    final staleDetail = container.read(
      transactionEntryDetailProvider((hash: 'confirmed-hash', isPending: false))
          .future,
    );
    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'wallet-b', repository: repositoryB));
    gate.complete(_confirmedTransaction());

    await expectLater(staleDetail, throwsStateError);
  });

  test(
    'destination matching passes typed data and keeps only exact matches',
    () async {
      final repository = _FakeNativeWalletRepository(
        confirmed: _confirmedTransaction(
          transfers: [
            _outgoingTransfer('xel:exact', _typedExtraData),
            _outgoingTransfer('xel:base-only', _typedExtraData),
            _outgoingTransfer('xel:ambiguous', _typedExtraData),
            _outgoingTransfer('xel:none', _typedExtraData),
          ],
        ),
        matches: {
          'xel:exact': XelisAddressBookExactMatch(_addressBookEntry('exact')),
          'xel:base-only': XelisAddressBookBaseOnlyMatch(
            _addressBookEntry('base-only'),
          ),
          'xel:ambiguous': XelisAddressBookAmbiguousMatch([
            _addressBookEntry('ambiguous-a'),
            _addressBookEntry('ambiguous-b'),
          ]),
          'xel:none': const XelisAddressBookNoMatch(),
        },
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final matches = await container.read(
        transactionExactDestinationsProvider((
          hash: 'confirmed-hash',
          isPending: false,
        )).future,
      );

      expect(matches[0]?.id, 'exact');
      expect(matches.skip(1), everyElement(isNull));
      expect(repository.matchCalls.map((call) => call.baseAddress), [
        'xel:exact',
        'xel:base-only',
        'xel:ambiguous',
        'xel:none',
      ]);
      expect(
        repository.matchCalls.map((call) => call.integratedData),
        everyElement(equals(_typedPayload)),
      );
    },
  );

  test(
    'does not downgrade unavailable attached data to a standard destination',
    () async {
      final repository = _FakeNativeWalletRepository(
        confirmed: _confirmedTransaction(
          transfers: [
            _outgoingTransfer('xel:standard', null),
            _outgoingTransfer('xel:failed', _failedExtraData),
            _outgoingTransfer('xel:empty', _emptyExtraData),
          ],
        ),
        matches: {
          'xel:standard': XelisAddressBookExactMatch(
            _standardAddressBookEntry('standard'),
          ),
          'xel:failed': XelisAddressBookExactMatch(
            _standardAddressBookEntry('failed'),
          ),
          'xel:empty': XelisAddressBookExactMatch(
            _standardAddressBookEntry('empty'),
          ),
        },
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      final matches = await container.read(
        transactionExactDestinationsProvider((
          hash: 'confirmed-hash',
          isPending: false,
        )).future,
      );

      expect(matches[0]?.id, 'standard');
      expect(matches.skip(1), everyElement(isNull));
      expect(repository.matchCalls, [
        (baseAddress: 'xel:standard', integratedData: null),
      ]);
    },
  );

  test('history and pending lists explicitly request metadata only', () async {
    final repository = _FakeNativeWalletRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(pendingTransactionsProvider.future);
    await container.read(lastTransactionsProvider.future);

    expect(repository.pendingListDisclosures, [
      XelisWalletExtraDataDisclosure.metadata,
    ]);
    expect(repository.historyDisclosures, [
      XelisWalletExtraDataDisclosure.metadata,
    ]);
  });

  test('route detail keeps confirmed and pending snapshots distinct', () {
    final confirmed = TransactionEntryDetail.fromRouteExtra(
      _confirmedTransaction(),
    );
    final pending = TransactionEntryDetail.fromRouteExtra(
      _pendingTransaction(),
    );

    expect(confirmed.request, (hash: 'confirmed-hash', isPending: false));
    expect(confirmed.topoheight, BigInt.from(10));
    expect(pending.request, (hash: 'pending-hash', isPending: true));
    expect(pending.topoheight, isNull);
  });

  test(
    'outgoing rows use the canonical destination only after exact match',
    () {
      final outgoing =
          _confirmedTransaction(
                transfers: [_outgoingTransfer('xel:base', _typedExtraData)],
              ).entry
              as XelisWalletOutgoingEntry;
      final exactEntry = _addressBookEntry('exact');

      final exactRows = entryRowFromOutgoing(
        outgoing,
        const {},
        false,
        exactDestinations: [exactEntry],
      );
      final unmatchedRows = entryRowFromOutgoing(outgoing, const {}, false);

      expect(exactRows.single.destination, exactEntry.destination.address);
      expect(exactRows.single.destinationIsExactMatch, isTrue);
      expect(unmatchedRows.single.destination, 'xel:base');
      expect(unmatchedRows.single.destinationIsExactMatch, isFalse);
    },
  );
}

ProviderContainer _container(NativeWalletRepository repository) =>
    ProviderContainer(
      overrides: [activeWalletRepositoryProvider.overrideWithValue(repository)],
    );

XelisWalletTransactionEntry _confirmedTransaction({
  List<XelisWalletTransferOut> transfers = const [],
}) => XelisWalletTransactionEntry(
  hash: 'confirmed-hash',
  topoheight: BigInt.from(10),
  timestampMillis: BigInt.from(20),
  entry: XelisWalletOutgoingEntry(
    transfers: transfers,
    fee: BigInt.one,
    nonce: BigInt.one,
  ),
);

XelisWalletPendingTransaction _pendingTransaction({
  List<XelisWalletTransferOut> transfers = const [],
}) => XelisWalletPendingTransaction(
  hash: 'pending-hash',
  timestampMillis: BigInt.from(20),
  entry: XelisWalletOutgoingEntry(
    transfers: transfers,
    fee: BigInt.one,
    nonce: BigInt.one,
  ),
);

XelisWalletTransferOut _outgoingTransfer(
  String destination,
  XelisWalletExtraData? extraData,
) => XelisWalletTransferOut(
  destination: destination,
  asset: 'asset',
  amount: BigInt.one,
  extraData: extraData,
);

XelisAddressBookEntry _addressBookEntry(String id) => XelisAddressBookEntry(
  id: id,
  displayName: 'Contact $id',
  destination: XelisSavedDestination(
    address: 'xel:integrated-$id',
    baseAddress: 'xel:$id',
    kind: XelisSavedDestinationKind.integrated,
    integratedDataKind: XelisIntegratedDataKind.string,
  ),
);

XelisAddressBookEntry _standardAddressBookEntry(String id) =>
    XelisAddressBookEntry(
      id: id,
      displayName: 'Contact $id',
      destination: XelisSavedDestination(
        address: 'xel:$id',
        baseAddress: 'xel:$id',
        kind: XelisSavedDestinationKind.standard,
        integratedDataKind: null,
      ),
    );

final _typedPayload = XelisDataElement.value(
  const XelisDataValue.string('typed payload'),
);
final _typedExtraData = XelisWalletExtraData(
  flag: XelisWalletExtraDataFlag.private,
  hasPayload: true,
  payload: _typedPayload,
);
const _failedExtraData = XelisWalletExtraData(
  flag: XelisWalletExtraDataFlag.failed,
  hasPayload: true,
);
const _emptyExtraData = XelisWalletExtraData(
  flag: XelisWalletExtraDataFlag.public,
  hasPayload: false,
);

typedef _MatchCall = ({String baseAddress, XelisDataElement? integratedData});

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  _FakeNativeWalletRepository({
    this.confirmed,
    this.pending,
    this.matches = const {},
  });

  final XelisWalletTransactionEntry? confirmed;
  final XelisWalletPendingTransaction? pending;
  final Map<String, XelisAddressBookMatch> matches;
  final List<String> confirmedHashes = [];
  final List<String> pendingHashes = [];
  final List<XelisWalletExtraDataDisclosure> confirmedDisclosures = [];
  final List<XelisWalletExtraDataDisclosure> pendingDetailDisclosures = [];
  final List<XelisWalletExtraDataDisclosure> historyDisclosures = [];
  final List<XelisWalletExtraDataDisclosure> pendingListDisclosures = [];
  final List<_MatchCall> matchCalls = [];
  Completer<XelisWalletTransactionEntry>? nextConfirmed;

  @override
  Future<XelisWalletTransactionEntry> transactionByHash({
    required String hash,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.detailed,
  }) async {
    confirmedHashes.add(hash);
    confirmedDisclosures.add(extraDataDisclosure);
    final gate = nextConfirmed;
    nextConfirmed = null;
    return gate?.future ?? confirmed ?? _confirmedTransaction();
  }

  @override
  Future<XelisWalletPendingTransaction> pendingTransactionByHash({
    required String hash,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.detailed,
  }) async {
    pendingHashes.add(hash);
    pendingDetailDisclosures.add(extraDataDisclosure);
    return pending ?? _pendingTransaction();
  }

  @override
  Future<List<XelisWalletTransactionEntry>> history({
    required XelisWalletHistoryFilter filter,
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.metadata,
  }) async {
    historyDisclosures.add(extraDataDisclosure);
    return const [];
  }

  @override
  Future<List<XelisWalletPendingTransaction>> pendingTransactions({
    XelisWalletExtraDataDisclosure extraDataDisclosure =
        XelisWalletExtraDataDisclosure.metadata,
  }) async {
    pendingListDisclosures.add(extraDataDisclosure);
    return const [];
  }

  @override
  Future<XelisAddressBookMatch> matchAddressBookDestination({
    required String baseAddress,
    XelisDataElement? integratedData,
  }) async {
    matchCalls.add((baseAddress: baseAddress, integratedData: integratedData));
    return matches[baseAddress] ?? const XelisAddressBookNoMatch();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
