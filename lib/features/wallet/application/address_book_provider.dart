import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

part 'address_book_provider.g.dart';

@riverpod
class AddressBook extends _$AddressBook {
  static const int pageSize = 50;
  Map<String, XelisAddressBookEntry> _allEntries = {};
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _generation = 0;

  @override
  Future<Map<String, XelisAddressBookEntry>> build() async {
    final repository = ref.watch(activeWalletRepositoryProvider);
    final query = _normalizeQuery(ref.watch(searchQueryProvider));
    final generation = ++_generation;
    _allEntries = {};
    _hasMore = true;
    _isLoadingMore = false;
    return _loadMore(
      repository: repository,
      query: query,
      generation: generation,
    );
  }

  Future<Map<String, XelisAddressBookEntry>> loadMore() async {
    final generation = _generation;
    final repository = ref.read(activeWalletRepositoryProvider);
    final query = _normalizeQuery(ref.read(searchQueryProvider));
    return _loadMore(
      repository: repository,
      query: query,
      generation: generation,
    );
  }

  Future<Map<String, XelisAddressBookEntry>> _loadMore({
    required NativeWalletRepository? repository,
    required String query,
    required int generation,
  }) async {
    if (!_hasMore || _isLoadingMore) return _snapshot;

    if (repository == null) {
      if (_isCurrent(generation, repository, query)) {
        _hasMore = false;
      }
      return _snapshot;
    }

    _isLoadingMore = true;
    try {
      final page = await repository.addressBookEntries(
        query: query.isEmpty ? null : query,
        skip: _allEntries.length,
        take: pageSize,
      );
      if (!_isCurrent(generation, repository, query)) {
        return _snapshot;
      }

      for (final entry in page.entries) {
        _allEntries[entry.id] = entry;
      }

      _hasMore = page.hasMore;
      final snapshot = _snapshot;
      state = AsyncData(snapshot);
      return snapshot;
    } finally {
      if (_isCurrent(generation, repository, query)) {
        _isLoadingMore = false;
      }
    }
  }

  bool get hasMore => _hasMore;

  void reset() {
    _generation++;
    _allEntries = {};
    _hasMore = true;
    _isLoadingMore = false;
    ref.invalidate(addressBookByAddressProvider);
    ref.invalidateSelf();
  }

  Future<XelisAddressBookEntry?> getById(String entryId) async {
    final generation = _generation;
    final repository = ref.read(activeWalletRepositoryProvider);
    final query = _normalizeQuery(ref.read(searchQueryProvider));
    final loaded = _allEntries[entryId];
    if (loaded != null && _isCurrent(generation, repository, query)) {
      return loaded;
    }

    final entry = await repository?.addressBookEntry(entryId);
    return _isCurrent(generation, repository, query) ? entry : null;
  }

  Future<XelisAddressBookEntry?> exactEntryForAddress(String address) async {
    final match = await matchAddress(address);
    return switch (match) {
      XelisAddressBookExactMatch(:final entry) => entry,
      _ => null,
    };
  }

  Future<bool> containsExactAddress(String address) async {
    return await exactEntryForAddress(address) != null;
  }

  Future<XelisAddressBookEntry> upsert({
    required String address,
    required String displayName,
    String? destinationLabel,
    String? note,
  }) async {
    final generation = _generation;
    final repository = ref.read(activeWalletRepositoryProvider);
    final query = _normalizeQuery(ref.read(searchQueryProvider));
    if (repository == null) {
      throw StateError('No active wallet repository.');
    }

    final entry = await repository.upsertAddressBookEntry(
      address: address,
      displayName: displayName,
      destinationLabel: destinationLabel,
      note: note,
    );
    _requireCurrent(generation, repository, query);
    reset();
    return entry;
  }

  Future<void> remove(String entryId) async {
    final generation = _generation;
    final repository = ref.read(activeWalletRepositoryProvider);
    final query = _normalizeQuery(ref.read(searchQueryProvider));
    if (repository == null) {
      throw StateError('No active wallet repository.');
    }

    await repository.removeAddressBookEntry(entryId);
    _requireCurrent(generation, repository, query);
    _allEntries.remove(entryId);
    state = AsyncData(_snapshot);
    ref.invalidate(addressBookByAddressProvider);
  }

  Future<XelisAddressBookMatch> matchAddress(String address) async {
    final generation = _generation;
    final repository = ref.read(activeWalletRepositoryProvider);
    final query = _normalizeQuery(ref.read(searchQueryProvider));
    if (repository == null) return const XelisAddressBookNoMatch();
    final match = await repository.matchAddressBookAddress(address);
    return _isCurrent(generation, repository, query)
        ? match
        : const XelisAddressBookNoMatch();
  }

  Future<XelisAddressBookMatch> matchDestination({
    required String baseAddress,
    XelisDataElement? integratedData,
  }) async {
    final generation = _generation;
    final repository = ref.read(activeWalletRepositoryProvider);
    final query = _normalizeQuery(ref.read(searchQueryProvider));
    if (repository == null) return const XelisAddressBookNoMatch();
    final match = await repository.matchAddressBookDestination(
      baseAddress: baseAddress,
      integratedData: integratedData,
    );
    return _isCurrent(generation, repository, query)
        ? match
        : const XelisAddressBookNoMatch();
  }

  bool _isCurrent(
    int generation,
    NativeWalletRepository? repository,
    String query,
  ) {
    return generation == _generation &&
        identical(ref.read(activeWalletRepositoryProvider), repository) &&
        _normalizeQuery(ref.read(searchQueryProvider)) == query;
  }

  void _requireCurrent(
    int generation,
    NativeWalletRepository repository,
    String query,
  ) {
    if (!_isCurrent(generation, repository, query)) {
      throw StateError('The active wallet or address-book search changed.');
    }
  }

  Map<String, XelisAddressBookEntry> get _snapshot =>
      Map.unmodifiable(_allEntries);
}

String _normalizeQuery(String query) => query.trim();

Map<String, XelisAddressBookEntry> addressBookEntriesByAddress(
  Iterable<XelisAddressBookEntry> entries,
) => Map.unmodifiable({
  for (final entry in entries) entry.destination.address: entry,
});

final addressBookByAddressProvider =
    FutureProvider<Map<String, XelisAddressBookEntry>>(
      _loadAddressBookByAddress,
    );

Future<Map<String, XelisAddressBookEntry>> _loadAddressBookByAddress(
  Ref ref,
) async {
  final repository = ref.watch(activeWalletRepositoryProvider);
  if (repository == null) return const {};

  final entries = <XelisAddressBookEntry>[];
  var skip = 0;
  while (true) {
    final page = await repository.addressBookEntries(
      skip: skip,
      take: AddressBook.pageSize,
    );
    if (!identical(ref.read(activeWalletRepositoryProvider), repository)) {
      throw StateError('The active wallet changed while indexing contacts.');
    }

    entries.addAll(page.entries);
    if (!page.hasMore) {
      return addressBookEntriesByAddress(entries);
    }
    if (page.entries.isEmpty) {
      throw StateError('Address-book pagination did not make progress.');
    }
    skip += page.entries.length;
  }
}
