import 'dart:convert';

import 'package:genesix/features/news/domain/news_item.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';
import 'package:http/http.dart' as http;

class NewsRepository {
  NewsRepository({
    required this.client,
    required this.storage,
    required this.indexUri,
    required this.bundledFeedLoader,
  });

  static const cacheStorageKey = 'news_feed_cache_v1';
  static const dismissedIdsStorageKey = 'news_dismissed_ids_v2';

  final http.Client client;
  final GenesixSharedPreferences storage;
  final Uri indexUri;
  final Future<String> Function() bundledFeedLoader;

  Future<NewsFeed> fetchFeed({String? walletScope}) async {
    try {
      final response = await client.get(indexUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _readCachedOrBundledFeed();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _readCachedOrBundledFeed();
      }

      await storage.save(key: cacheStorageKey, value: decoded);
      final feed = NewsFeed.fromJson(decoded);
      if (walletScope != null) {
        await pruneDismissedIds(feed, walletScope: walletScope);
      }
      return feed;
    } catch (_) {
      return _readCachedOrBundledFeed();
    }
  }

  Set<String> dismissedIds({required String walletScope}) {
    final dismissedIdsByWallet = _dismissedIdsByWallet();
    final ids = dismissedIdsByWallet[walletScope];
    if (ids is! List) {
      return {};
    }

    return ids.whereType<String>().toSet();
  }

  Map<String, dynamic> _dismissedIdsByWallet() {
    if (!storage.prefs.containsKey(dismissedIdsStorageKey)) {
      return {};
    }

    final value = storage.get(key: dismissedIdsStorageKey);
    if (value is! Map<String, dynamic>) {
      return {};
    }

    final wallets = value['wallets'];
    if (wallets is! Map<String, dynamic>) {
      return {};
    }

    return Map<String, dynamic>.from(wallets);
  }

  Future<void> dismiss(String id, {required String walletScope}) async {
    final ids = dismissedIds(walletScope: walletScope)..add(id);
    await _saveDismissedIds(walletScope, ids);
  }

  Future<void> pruneDismissedIds(
    NewsFeed feed, {
    required String walletScope,
  }) async {
    final activeIds = feed.items.map((item) => item.id).toSet();
    final ids = dismissedIds(walletScope: walletScope);
    final prunedIds = ids.intersection(activeIds);

    if (prunedIds.length == ids.length) {
      return;
    }

    await _saveDismissedIds(walletScope, prunedIds);
  }

  NewsFeed _readCachedFeed() {
    if (!storage.prefs.containsKey(cacheStorageKey)) {
      return NewsFeed.empty();
    }

    final cached = storage.get(key: cacheStorageKey);
    if (cached is! Map<String, dynamic>) {
      return NewsFeed.empty();
    }

    return NewsFeed.fromJson(cached);
  }

  Future<NewsFeed> _readCachedOrBundledFeed() async {
    final cached = _readCachedFeed();
    if (cached.items.isNotEmpty) {
      return cached;
    }

    try {
      final decoded = jsonDecode(await bundledFeedLoader());
      if (decoded is! Map<String, dynamic>) {
        return NewsFeed.empty();
      }

      return NewsFeed.fromJson(decoded);
    } catch (_) {
      return NewsFeed.empty();
    }
  }

  Future<void> _saveDismissedIds(String walletScope, Set<String> ids) async {
    final dismissedIdsByWallet = _dismissedIdsByWallet();
    if (ids.isEmpty) {
      dismissedIdsByWallet.remove(walletScope);
    } else {
      dismissedIdsByWallet[walletScope] = ids.toList(growable: false)..sort();
    }

    await storage.save(
      key: dismissedIdsStorageKey,
      value: {'wallets': dismissedIdsByWallet},
    );
  }
}
