import 'package:genesix/features/news/domain/news_feed_contract.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';

class NewsFeed {
  const NewsFeed({required this.items});

  final List<NewsItem> items;

  factory NewsFeed.empty() => const NewsFeed(items: []);

  factory NewsFeed.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      return NewsFeed.empty();
    }

    final items = <NewsItem>[];
    for (final rawItem in rawItems.take(50)) {
      if (rawItem is! Map<String, dynamic>) {
        continue;
      }

      final item = NewsItem.tryParse(rawItem);
      if (item != null) {
        items.add(item);
      }
    }

    items.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return NewsFeed(items: items);
  }
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.publishedAt,
    required this.type,
    required this.severity,
    required this.title,
    required this.summary,
    required this.targets,
    required this.links,
    this.expiresAt,
  });

  final String id;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final NewsType type;
  final NewsSeverity severity;
  final LocalizedNewsText title;
  final LocalizedNewsText summary;
  final NewsTargets targets;
  final List<NewsLink> links;

  static NewsItem? tryParse(Map<String, dynamic> json) {
    final id = _stringValue(json['id']);
    final publishedAt = _dateValue(json['publishedAt']);
    final title = LocalizedNewsText.tryParse(json['title']);
    final summary = LocalizedNewsText.tryParse(json['summary']);

    if (id == null || publishedAt == null || title == null || summary == null) {
      return null;
    }

    final rawLinks = json['links'];
    final links = rawLinks is List
        ? rawLinks
              .take(3)
              .whereType<Map<String, dynamic>>()
              .map(NewsLink.tryParse)
              .nonNulls
              .toList(growable: false)
        : const <NewsLink>[];

    return NewsItem(
      id: id,
      publishedAt: publishedAt,
      expiresAt: _dateValue(json['expiresAt']),
      type: NewsType.fromJson(json['type']),
      severity: NewsSeverity.fromJson(json['severity']),
      title: title,
      summary: summary,
      targets: NewsTargets.fromJson(json['targets']),
      links: links,
    );
  }

  bool isVisibleFor({
    required String languageCode,
    required Network network,
    required String platform,
    required String appVersion,
    required Set<String> dismissedIds,
    required DateTime now,
  }) {
    if (expiresAt != null && !expiresAt!.isAfter(now)) {
      return false;
    }
    if (publishedAt.isAfter(now.add(const Duration(minutes: 5)))) {
      return false;
    }
    if (!title.supports(languageCode) && !summary.supports(languageCode)) {
      return false;
    }
    if (!targets.supportsNetwork(network.name)) {
      return false;
    }
    if (!targets.supportsPlatform(platform)) {
      return false;
    }
    if (!targets.supportsAppVersion(appVersion)) {
      return false;
    }
    if (dismissedIds.contains(id) && severity != NewsSeverity.critical) {
      return false;
    }

    return true;
  }

  String titleFor(String languageCode) => title.resolve(languageCode);

  String summaryFor(String languageCode) => summary.resolve(languageCode);

  NewsLink? get primaryLink => links.firstOrNull;
}

class LocalizedNewsText {
  const LocalizedNewsText(this.values);

  final Map<String, String> values;

  static LocalizedNewsText? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }

    final values = <String, String>{};
    for (final entry in raw.entries) {
      final languageCode = entry.key.trim().toLowerCase();
      final text = _stringValue(entry.value);
      if (languageCode.isNotEmpty && text != null) {
        values[languageCode] = text;
      }
    }

    return values.isEmpty ? null : LocalizedNewsText(values);
  }

  bool supports(String languageCode) {
    return values.containsKey(languageCode.toLowerCase()) ||
        values.containsKey('en') ||
        values.isNotEmpty;
  }

  String resolve(String languageCode) {
    return values[languageCode.toLowerCase()] ??
        values['en'] ??
        values.values.first;
  }
}

class NewsTargets {
  const NewsTargets({
    required this.networks,
    required this.platforms,
    this.minAppVersion,
    this.maxAppVersion,
  });

  final Set<String> networks;
  final Set<String> platforms;
  final String? minAppVersion;
  final String? maxAppVersion;

  factory NewsTargets.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return const NewsTargets(networks: {}, platforms: {});
    }

    return NewsTargets(
      networks: _stringSet(raw['networks']),
      platforms: _stringSet(raw['platforms']),
      minAppVersion: _stringValue(raw['minAppVersion']),
      maxAppVersion: _stringValue(raw['maxAppVersion']),
    );
  }

  bool supportsNetwork(String network) {
    return networks.isEmpty || networks.contains(network.toLowerCase());
  }

  bool supportsPlatform(String platform) {
    return platforms.isEmpty || platforms.contains(platform.toLowerCase());
  }

  bool supportsAppVersion(String appVersion) {
    if (minAppVersion != null &&
        _compareVersions(appVersion, minAppVersion!) < 0) {
      return false;
    }
    if (maxAppVersion != null &&
        _compareVersions(appVersion, maxAppVersion!) > 0) {
      return false;
    }

    return true;
  }
}

class NewsLink {
  const NewsLink({required this.label, required this.url});

  final LocalizedNewsText label;
  final Uri url;

  static NewsLink? tryParse(Map<String, dynamic> json) {
    final label = LocalizedNewsText.tryParse(json['label']);
    final rawUrl = _stringValue(json['url']);
    final url = rawUrl == null ? null : Uri.tryParse(rawUrl);

    if (label == null || url == null || !isAllowedNewsUrl(url)) {
      return null;
    }

    return NewsLink(label: label, url: url);
  }
}

enum NewsType {
  update,
  security,
  network,
  announcement;

  static NewsType fromJson(Object? value) {
    return switch (_stringValue(value)?.toLowerCase()) {
      'security' => NewsType.security,
      'network' => NewsType.network,
      'announcement' => NewsType.announcement,
      _ => NewsType.update,
    };
  }
}

enum NewsSeverity {
  info,
  warning,
  critical;

  static NewsSeverity fromJson(Object? value) {
    return switch (_stringValue(value)?.toLowerCase()) {
      'warning' => NewsSeverity.warning,
      'critical' => NewsSeverity.critical,
      _ => NewsSeverity.info,
    };
  }
}

String? _stringValue(Object? value) {
  if (value is! String) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateValue(Object? value) {
  final string = _stringValue(value);
  return string == null ? null : DateTime.tryParse(string)?.toUtc();
}

Set<String> _stringSet(Object? raw) {
  if (raw is! List) {
    return {};
  }

  return raw
      .whereType<String>()
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();
}

int _compareVersions(String left, String right) {
  final leftParts = _versionParts(left);
  final rightParts = _versionParts(right);
  final length = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;

  for (var i = 0; i < length; i++) {
    final leftPart = i < leftParts.length ? leftParts[i] : 0;
    final rightPart = i < rightParts.length ? rightParts[i] : 0;
    if (leftPart != rightPart) {
      return leftPart.compareTo(rightPart);
    }
  }

  return 0;
}

List<int> _versionParts(String version) {
  return version
      .split(RegExp(r'[^0-9]+'))
      .where((part) => part.isNotEmpty)
      .map(int.tryParse)
      .nonNulls
      .toList(growable: false);
}
