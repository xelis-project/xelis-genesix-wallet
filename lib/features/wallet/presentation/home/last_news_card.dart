import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/news/application/news_providers.dart';
import 'package:genesix/features/news/domain/news_item.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class LastNewsCard extends ConsumerWidget {
  const LastNewsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final newsAsync = ref.watch(visibleNewsProvider);

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.last_news,
                  style: context.theme.typography.display.xl.copyWith(
                    color: context.theme.colors.primary,
                  ),
                ),
              ),
              FTooltip(
                tipBuilder: (context, controller) => Text(loc.refresh),
                child: FButton.icon(
                  child: const Icon(FLucideIcons.refreshCcw),
                  onPress: () => ref.invalidate(visibleNewsProvider),
                ),
              ),
            ],
          ),
          newsAsync.when(
            data: (items) => _NewsList(items: items),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: Spaces.small),
              child: Center(child: FCircularProgress()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.only(top: Spaces.small),
              child: Text(
                loc.no_recent_news,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsList extends ConsumerWidget {
  const _NewsList({required this.items});

  final List<NewsItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final languageCode = loc.localeName.split('_').first.toLowerCase();

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: Spaces.small),
        child: Text(
          loc.no_recent_news,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: Spaces.small),
      child: Column(
        spacing: Spaces.small,
        children: [
          for (final item in items)
            _NewsTile(
              item: item,
              languageCode: languageCode,
              icon: _iconFor(item),
              iconColor: _colorFor(context, item),
              badgeVariant: _badgeVariantFor(item),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(NewsItem item) {
    if (item.severity == NewsSeverity.critical) {
      return FLucideIcons.circleAlert;
    }

    return switch (item.type) {
      NewsType.security => FLucideIcons.shieldCheck,
      NewsType.network => FLucideIcons.waypoints,
      NewsType.announcement => FLucideIcons.info,
      NewsType.update => FLucideIcons.sparkles,
    };
  }

  Color _colorFor(BuildContext context, NewsItem item) {
    return switch (item.severity) {
      NewsSeverity.critical => context.theme.colors.destructive,
      NewsSeverity.warning => Colors.orange.shade600,
      NewsSeverity.info => context.theme.colors.primary,
    };
  }

  FBadgeVariant _badgeVariantFor(NewsItem item) {
    return switch (item.severity) {
      NewsSeverity.critical => FBadgeVariant.destructive,
      NewsSeverity.warning => FBadgeVariant.secondary,
      NewsSeverity.info => FBadgeVariant.outline,
    };
  }
}

class _NewsTile extends ConsumerWidget {
  const _NewsTile({
    required this.item,
    required this.languageCode,
    required this.icon,
    required this.iconColor,
    required this.badgeVariant,
  });

  final NewsItem item;
  final String languageCode;
  final IconData icon;
  final Color iconColor;
  final FBadgeVariant badgeVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tile = _NewsTileContent(
      item: item,
      languageCode: languageCode,
      icon: icon,
      iconColor: iconColor,
      badgeVariant: badgeVariant,
    );

    if (item.severity == NewsSeverity.critical) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('news:${item.id}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: _DismissBackground(),
      onDismissed: (_) =>
          ref.read(dismissedNewsIdsProvider.notifier).dismiss(item.id),
      child: tile,
    );
  }
}

class _NewsTileContent extends StatelessWidget {
  const _NewsTileContent({
    required this.item,
    required this.languageCode,
    required this.icon,
    required this.iconColor,
    required this.badgeVariant,
  });

  final NewsItem item;
  final String languageCode;
  final IconData icon;
  final Color iconColor;
  final FBadgeVariant badgeVariant;

  @override
  Widget build(BuildContext context) {
    return FItem(
      prefix: Icon(icon, color: iconColor, size: 18),
      title: Text(
        item.titleFor(languageCode),
        style: context.theme.typography.body.sm.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.summaryFor(languageCode),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.theme.typography.body.xs.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      details: FBadge(variant: badgeVariant, child: Text(item.type.name)),
      suffix: const Icon(FLucideIcons.chevronRight),
      onPress: () => _showNewsDetails(context),
    );
  }

  Future<void> _showNewsDetails(BuildContext context) {
    return showAppDialog<void>(
      context: context,
      builder: (context, style, animation) {
        return _NewsDetailsDialog(
          item: item,
          languageCode: languageCode,
          style: style,
          animation: animation,
        );
      },
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
      decoration: BoxDecoration(
        color: context.theme.colors.destructive.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(FLucideIcons.x, color: context.theme.colors.destructive),
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton();

  @override
  Widget build(BuildContext context) {
    return FButton.icon(
      variant: .ghost,
      child: const Icon(FLucideIcons.x),
      onPress: () => Navigator.of(context, rootNavigator: true).pop(),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({
    required this.item,
    required this.languageCode,
    required this.closeButton,
  });

  final NewsItem item;
  final String languageCode;
  final Widget closeButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(item.titleFor(languageCode))),
        const SizedBox(width: Spaces.small),
        closeButton,
      ],
    );
  }
}

class _DialogActions extends ConsumerWidget {
  const _DialogActions({
    required this.item,
    required this.languageCode,
    required this.link,
  });

  final NewsItem item;
  final String languageCode;
  final NewsLink? link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    if (link == null && item.severity == NewsSeverity.critical) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: Spaces.small,
      runSpacing: Spaces.small,
      alignment: WrapAlignment.end,
      children: [
        if (item.severity != NewsSeverity.critical)
          FButton(
            variant: .outline,
            onPress: () => _dismiss(context, ref),
            child: Text(loc.dismiss),
          ),
        if (link != null)
          FButton(
            onPress: () => _openLink(context, link!),
            child: Text(link!.label.resolve(languageCode)),
          ),
      ],
    );
  }

  void _openLink(BuildContext context, NewsLink link) {
    Navigator.of(context, rootNavigator: true).pop();
    unawaited(launchUrl(link.url, mode: LaunchMode.externalApplication));
  }

  void _dismiss(BuildContext context, WidgetRef ref) {
    Navigator.of(context, rootNavigator: true).pop();
    unawaited(ref.read(dismissedNewsIdsProvider.notifier).dismiss(item.id));
  }
}

class _NewsSource extends StatelessWidget {
  const _NewsSource({required this.link});

  final NewsLink link;

  @override
  Widget build(BuildContext context) {
    final url = link.url.toString();

    return Text(
      url,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.theme.typography.body.xs.copyWith(
        color: context.theme.colors.primary,
        decoration: TextDecoration.underline,
        decorationColor: context.theme.colors.primary,
      ),
    );
  }
}

class _NewsDialogBody extends StatelessWidget {
  const _NewsDialogBody({
    required this.item,
    required this.languageCode,
    required this.badgeVariant,
    required this.link,
  });

  final NewsItem item;
  final String languageCode;
  final FBadgeVariant badgeVariant;
  final NewsLink? link;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FBadge(variant: badgeVariant, child: Text(item.type.name)),
        const SizedBox(height: Spaces.small),
        Text(item.summaryFor(languageCode)),
        if (link != null) const SizedBox(height: Spaces.small),
        if (link != null) _NewsSource(link: link!),
        const SizedBox(height: Spaces.medium),
        _DialogActions(item: item, languageCode: languageCode, link: link),
      ],
    );
  }
}

class _NewsDetailsDialog extends ConsumerWidget {
  const _NewsDetailsDialog({
    required this.item,
    required this.languageCode,
    required this.style,
    required this.animation,
  });

  final NewsItem item;
  final String languageCode;
  final FDialogStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = item.primaryLink;
    final badgeVariant = _badgeVariantFor(item);

    return FDialog(
      style: style,
      animation: animation,
      direction: Axis.horizontal,
      title: _DialogTitle(
        item: item,
        languageCode: languageCode,
        closeButton: const _DialogCloseButton(),
      ),
      body: _NewsDialogBody(
        item: item,
        languageCode: languageCode,
        badgeVariant: badgeVariant,
        link: link,
      ),
      actions: const [],
    );
  }

  FBadgeVariant _badgeVariantFor(NewsItem item) {
    return switch (item.severity) {
      NewsSeverity.critical => FBadgeVariant.destructive,
      NewsSeverity.warning => FBadgeVariant.secondary,
      NewsSeverity.info => FBadgeVariant.outline,
    };
  }
}
