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
  static const dismissedIdsStorageKey = 'news_dismissed_ids_v1';

  final http.Client client;
  final GenesixSharedPreferences storage;
  final Uri indexUri;
  final Future<String> Function() bundledFeedLoader;

  Future<NewsFeed> fetchFeed() async {
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
      await pruneDismissedIds(feed);
      return feed;
    } catch (_) {
      return _readCachedOrBundledFeed();
    }
  }

  Set<String> dismissedIds() {
    if (!storage.prefs.containsKey(dismissedIdsStorageKey)) {
      return {};
    }

    final value = storage.get(key: dismissedIdsStorageKey);
    if (value is! Map<String, dynamic>) {
      return {};
    }

    final ids = value['ids'];
    if (ids is! List) {
      return {};
    }

    return ids.whereType<String>().toSet();
  }

  Future<void> dismiss(String id) async {
    final ids = dismissedIds()..add(id);
    await _saveDismissedIds(ids);
  }

  Future<void> pruneDismissedIds(NewsFeed feed) async {
    final activeIds = feed.items.map((item) => item.id).toSet();
    final ids = dismissedIds();
    final prunedIds = ids.intersection(activeIds);

    if (prunedIds.length == ids.length) {
      return;
    }

    await _saveDismissedIds(prunedIds);
  }

  NewsFeed _readCachedFeed() {
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

  Future<void> _saveDismissedIds(Set<String> ids) async {
    await storage.save(
      key: dismissedIdsStorageKey,
      value: {'ids': ids.toList(growable: false)..sort()},
    );
  }
}
