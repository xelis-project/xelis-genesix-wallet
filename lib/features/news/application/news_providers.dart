import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:genesix/features/news/data/news_repository.dart';
import 'package:genesix/features/news/domain/news_item.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'news_providers.g.dart';

const _defaultNewsIndexUrl =
    'https://xelis-project.github.io/xelis-genesix-wallet/news/index.json';

const _newsIndexUrl = String.fromEnvironment(
  'GENESIX_NEWS_INDEX_URL',
  defaultValue: _defaultNewsIndexUrl,
);

@riverpod
NewsRepository newsRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);

  return NewsRepository(
    client: client,
    storage: GenesixSharedPreferences(ref.watch(sharedPreferencesProvider)),
    indexUri: Uri.parse(_newsIndexUrl),
    bundledFeedLoader: () => rootBundle.loadString('news/index.json'),
  );
}

@riverpod
class DismissedNewsIds extends _$DismissedNewsIds {
  @override
  Set<String> build() {
    return ref.watch(newsRepositoryProvider).dismissedIds();
  }

  Future<void> dismiss(String id) async {
    await ref.read(newsRepositoryProvider).dismiss(id);
    state = {...state, id};
  }
}

@riverpod
Future<List<NewsItem>> visibleNews(Ref ref) async {
  final settings = ref.watch(settingsProvider);
  final locale = settings.locale;
  final network = settings.network;
  final dismissedIds = ref.watch(dismissedNewsIdsProvider);
  final packageInfo = await PackageInfo.fromPlatform();

  final timer = Timer(const Duration(hours: 6), ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  final feed = await ref.watch(newsRepositoryProvider).fetchFeed();
  final platform = _currentPlatformName();
  final languageCode = locale.languageCode.toLowerCase();
  final now = DateTime.now().toUtc();

  final visible = feed.items
      .where(
        (item) => item.isVisibleFor(
          languageCode: languageCode,
          network: network,
          platform: platform,
          appVersion: packageInfo.version,
          dismissedIds: dismissedIds,
          now: now,
        ),
      )
      .take(3)
      .toList(growable: false);

  ref.keepAlive();
  return visible;
}

String _currentPlatformName() {
  if (kIsWeb) {
    return 'web';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}
