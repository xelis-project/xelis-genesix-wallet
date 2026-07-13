import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/news/application/news_feed_config.dart';
import 'package:genesix/features/news/data/news_repository.dart';
import 'package:genesix/features/news/domain/news_item.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/storage/shared_preferences/genesix_shared_preferences.dart';
import 'package:genesix/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'news_providers.g.dart';

@riverpod
NewsRepository newsRepository(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);

  return NewsRepository(
    client: client,
    storage: GenesixSharedPreferences(ref.watch(sharedPreferencesProvider)),
    indexUri: Uri.parse(resolvedNewsIndexUrl),
    bundledFeedLoader: () => rootBundle.loadString(bundledNewsFeedAssetPath),
  );
}

@riverpod
class DismissedNewsIds extends _$DismissedNewsIds {
  @override
  Set<String> build() {
    final walletScope = _walletNewsScope(
      ref.watch(activeWalletSessionProvider),
    );
    if (walletScope == null) {
      return {};
    }

    return ref
        .watch(newsRepositoryProvider)
        .dismissedIds(walletScope: walletScope);
  }

  Future<void> dismiss(String id) async {
    final walletScope = _walletNewsScope(ref.read(activeWalletSessionProvider));
    if (walletScope == null) {
      return;
    }

    await ref
        .read(newsRepositoryProvider)
        .dismiss(id, walletScope: walletScope);

    final activeWalletScope = _walletNewsScope(
      ref.read(activeWalletSessionProvider),
    );
    if (activeWalletScope != walletScope) {
      return;
    }

    state = {...state, id};
  }
}

@riverpod
Future<List<NewsItem>> visibleNews(Ref ref) async {
  final walletScope = _walletNewsScope(ref.watch(activeWalletSessionProvider));
  if (walletScope == null) {
    return const <NewsItem>[];
  }

  final settings = ref.watch(settingsProvider);
  if (settings.walletOfflineMode) {
    return const <NewsItem>[];
  }

  final locale = settings.locale;
  final network = settings.network;
  final dismissedIds = ref.watch(dismissedNewsIdsProvider);
  final packageInfo = await PackageInfo.fromPlatform();

  final timer = Timer(newsFeedRefreshInterval, ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  final feed = await ref
      .watch(newsRepositoryProvider)
      .fetchFeed(walletScope: walletScope);
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
      .take(visibleNewsItemLimit)
      .toList(growable: false);

  return visible;
}

String? _walletNewsScope(WalletSession? session) {
  if (session == null) {
    return null;
  }

  final address = session.address.trim().toLowerCase();
  if (address.isEmpty) {
    return null;
  }

  final identity = '${session.network.name}:$address';
  return sha256.convert(utf8.encode(identity)).toString();
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
