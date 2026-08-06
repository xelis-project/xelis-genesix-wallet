import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  const baseAddress = 'xel:base-address';
  const integratedAddressA = 'xel:integrated-address-a';
  const integratedAddressB = 'xel:integrated-address-b';
  const entryA = XelisAddressBookEntry(
    id: 'entry-a',
    displayName: 'Exchange A',
    destination: XelisSavedDestination(
      address: integratedAddressA,
      baseAddress: baseAddress,
      kind: XelisSavedDestinationKind.integrated,
      integratedDataKind: XelisIntegratedDataKind.string,
    ),
  );
  const entryB = XelisAddressBookEntry(
    id: 'entry-b',
    displayName: 'Exchange B',
    destination: XelisSavedDestination(
      address: integratedAddressB,
      baseAddress: baseAddress,
      kind: XelisSavedDestinationKind.integrated,
      integratedDataKind: XelisIntegratedDataKind.u64,
    ),
  );

  test('indexes entries by stable id without merging a shared base', () async {
    final repository = _FakeNativeWalletRepository(entries: [entryA, entryB]);
    final harness = _AddressBookHarness(repository);
    addTearDown(harness.dispose);

    final entries = await harness.container.read(addressBookProvider.future);

    expect(entries.keys, containsAll(<String>['entry-a', 'entry-b']));
    expect(entries, hasLength(2));

    final byAddress = await harness.container.read(
      addressBookByAddressProvider.future,
    );
    expect(byAddress[integratedAddressA], same(entryA));
    expect(byAddress[integratedAddressB], same(entryB));
  });

  test(
    'global contact identities are independent from the search query',
    () async {
      final repository = _FakeNativeWalletRepository(entries: [entryA, entryB]);
      final harness = _AddressBookHarness(repository);
      addTearDown(harness.dispose);

      harness.container.read(searchQueryProvider.notifier).change('Exchange A');
      final searched = await harness.container.read(addressBookProvider.future);
      final byAddress = await harness.container.read(
        addressBookByAddressProvider.future,
      );

      expect(searched.values, [entryA]);
      expect(
        byAddress.keys,
        containsAll([integratedAddressA, integratedAddressB]),
      );
    },
  );

  test('removes an entry with its opaque id', () async {
    final repository = _FakeNativeWalletRepository(entries: [entryA, entryB]);
    final harness = _AddressBookHarness(repository);
    addTearDown(harness.dispose);
    await harness.container.read(addressBookProvider.future);

    await harness.container
        .read(addressBookProvider.notifier)
        .remove(entryA.id);

    expect(repository.removedEntryIds, [entryA.id]);
    expect(
      harness.container.read(addressBookProvider).value,
      isNot(contains(entryA.id)),
    );
    final byAddress = await harness.container.read(
      addressBookByAddressProvider.future,
    );
    expect(byAddress, isNot(contains(integratedAddressA)));
  });

  test('upserts the complete integrated destination', () async {
    final repository = _FakeNativeWalletRepository(entries: [entryA]);
    final harness = _AddressBookHarness(repository);
    addTearDown(harness.dispose);
    await harness.container.read(addressBookProvider.future);

    await harness.container
        .read(addressBookProvider.notifier)
        .upsert(
          address: integratedAddressA,
          displayName: 'Updated exchange',
          destinationLabel: 'Deposit',
          note: 'Keep the full address',
        );

    expect(repository.lastUpsertAddress, integratedAddressA);
    expect(repository.lastUpsertDisplayName, 'Updated exchange');
    expect(repository.lastUpsertDestinationLabel, 'Deposit');
  });

  test('treats only an exact destination match as an existing entry', () async {
    final repository = _FakeNativeWalletRepository(entries: [entryA]);
    final harness = _AddressBookHarness(repository);
    addTearDown(harness.dispose);
    await harness.container.read(addressBookProvider.future);
    final notifier = harness.container.read(addressBookProvider.notifier);

    repository.addressMatches[integratedAddressA] =
        const XelisAddressBookExactMatch(entryA);
    repository.addressMatches[baseAddress] =
        const XelisAddressBookBaseOnlyMatch(entryA);

    expect(await notifier.containsExactAddress(integratedAddressA), isTrue);
    expect(await notifier.containsExactAddress(baseAddress), isFalse);
  });

  test('discards a page completed by a replaced wallet', () async {
    final repositoryA = _FakeNativeWalletRepository(entries: [entryA]);
    final repositoryB = _FakeNativeWalletRepository(entries: [entryB]);
    final gate = Completer<XelisAddressBookPage>();
    repositoryA.nextPage = gate;
    final harness = _AddressBookHarness(repositoryA);
    addTearDown(harness.dispose);

    harness.setRepository(repositoryB, name: 'wallet-b');
    final current = await harness.container.read(addressBookProvider.future);
    gate.complete(_page([entryA]));
    await Future<void>.delayed(Duration.zero);

    expect(current.values, [entryB]);
    expect(harness.container.read(addressBookProvider).value?.values, [entryB]);
  });

  test('discards a page completed for an obsolete search', () async {
    final repository = _FakeNativeWalletRepository(entries: [entryB]);
    final gate = Completer<XelisAddressBookPage>();
    repository.nextPage = gate;
    final harness = _AddressBookHarness(repository);
    addTearDown(harness.dispose);

    harness.container.read(searchQueryProvider.notifier).change('exchange b');
    final current = await harness.container.read(addressBookProvider.future);
    gate.complete(_page([entryA]));
    await Future<void>.delayed(Duration.zero);

    expect(current.values, [entryB]);
    expect(harness.container.read(addressBookProvider).value?.values, [entryB]);
  });

  test('getById never returns an entry from a replaced wallet', () async {
    final repositoryA = _FakeNativeWalletRepository(entries: const []);
    final repositoryB = _FakeNativeWalletRepository(entries: [entryB]);
    final gate = Completer<XelisAddressBookEntry>();
    repositoryA.nextEntry = gate;
    final harness = _AddressBookHarness(repositoryA);
    addTearDown(harness.dispose);
    await harness.container.read(addressBookProvider.future);

    final staleRead = harness.container
        .read(addressBookProvider.notifier)
        .getById(entryA.id);
    harness.setRepository(repositoryB, name: 'wallet-b');
    gate.complete(entryA);

    expect(await staleRead, isNull);
    expect(await harness.container.read(addressBookProvider.future), {
      entryB.id: entryB,
    });
  });

  test(
    'stale writes fail instead of mutating the replacement wallet',
    () async {
      final repositoryA = _FakeNativeWalletRepository(entries: [entryA]);
      final repositoryB = _FakeNativeWalletRepository(entries: [entryB]);
      final upsertGate = Completer<XelisAddressBookEntry>();
      repositoryA.nextUpsert = upsertGate;
      final harness = _AddressBookHarness(repositoryA);
      addTearDown(harness.dispose);
      await harness.container.read(addressBookProvider.future);

      final staleWrite = harness.container
          .read(addressBookProvider.notifier)
          .upsert(address: integratedAddressA, displayName: 'Stale');
      harness.setRepository(repositoryB, name: 'wallet-b');
      upsertGate.complete(entryA);

      await expectLater(staleWrite, throwsStateError);
      expect(await harness.container.read(addressBookProvider.future), {
        entryB.id: entryB,
      });
    },
  );

  test('stale exact matches are reduced to no match', () async {
    final repositoryA = _FakeNativeWalletRepository(entries: [entryA]);
    final repositoryB = _FakeNativeWalletRepository(entries: [entryB]);
    final matchGate = Completer<XelisAddressBookMatch>();
    repositoryA.nextAddressMatch = matchGate;
    final harness = _AddressBookHarness(repositoryA);
    addTearDown(harness.dispose);
    await harness.container.read(addressBookProvider.future);

    final staleMatch = harness.container
        .read(addressBookProvider.notifier)
        .matchAddress(integratedAddressA);
    harness.setRepository(repositoryB, name: 'wallet-b');
    matchGate.complete(const XelisAddressBookExactMatch(entryA));

    expect(await staleMatch, isA<XelisAddressBookNoMatch>());
  });
}

final class _AddressBookHarness {
  _AddressBookHarness(NativeWalletRepository repository)
    : container = ProviderContainer() {
    setRepository(repository, name: 'wallet-a');
    subscription = container.listen(
      addressBookProvider,
      (_, _) {},
      fireImmediately: true,
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<
    AsyncValue<Map<String, XelisAddressBookEntry>>
  >
  subscription;

  void setRepository(
    NativeWalletRepository repository, {
    required String name,
  }) {
    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: name, repository: repository));
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  _FakeNativeWalletRepository({required List<XelisAddressBookEntry> entries})
    : entries = List.of(entries),
      upsertResult = entries.isEmpty ? null : entries.first;

  final List<XelisAddressBookEntry> entries;
  final XelisAddressBookEntry? upsertResult;
  final List<String> removedEntryIds = [];
  final Map<String, XelisAddressBookMatch> addressMatches = {};
  String? lastUpsertAddress;
  String? lastUpsertDisplayName;
  String? lastUpsertDestinationLabel;
  Completer<XelisAddressBookPage>? nextPage;
  Completer<XelisAddressBookEntry>? nextEntry;
  Completer<XelisAddressBookEntry>? nextUpsert;
  Completer<XelisAddressBookMatch>? nextAddressMatch;

  @override
  Future<XelisAddressBookPage> addressBookEntries({
    String? query,
    int skip = 0,
    int? take,
  }) async {
    final gate = nextPage;
    nextPage = null;
    if (gate != null) return gate.future;
    final filtered = query == null || query.isEmpty
        ? entries
        : entries
              .where(
                (entry) => entry.displayName.toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();
    return XelisAddressBookPage(
      entries: filtered.skip(skip).take(take ?? filtered.length).toList(),
      total: filtered.length,
      hasMore: false,
    );
  }

  @override
  Future<XelisAddressBookEntry> addressBookEntry(String entryId) async {
    final gate = nextEntry;
    nextEntry = null;
    if (gate != null) return gate.future;
    return entries.firstWhere((entry) => entry.id == entryId);
  }

  @override
  String get address => 'wallet-address';

  @override
  XelisNetwork get network => XelisNetwork.mainnet;

  @override
  Future<XelisAddressBookEntry> upsertAddressBookEntry({
    required String address,
    required String displayName,
    String? destinationLabel,
    String? note,
  }) async {
    lastUpsertAddress = address;
    lastUpsertDisplayName = displayName;
    lastUpsertDestinationLabel = destinationLabel;
    final gate = nextUpsert;
    nextUpsert = null;
    return gate?.future ??
        upsertResult ??
        (throw StateError('No fake upsert result configured.'));
  }

  @override
  Future<void> removeAddressBookEntry(String entryId) async {
    removedEntryIds.add(entryId);
    entries.removeWhere((entry) => entry.id == entryId);
  }

  @override
  Future<XelisAddressBookMatch> matchAddressBookAddress(String address) async {
    final gate = nextAddressMatch;
    nextAddressMatch = null;
    if (gate != null) return gate.future;
    return addressMatches[address] ?? const XelisAddressBookNoMatch();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

XelisAddressBookPage _page(List<XelisAddressBookEntry> entries) {
  return XelisAddressBookPage(
    entries: entries,
    total: entries.length,
    hasMore: false,
  );
}
