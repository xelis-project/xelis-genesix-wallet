import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:url_launcher/url_launcher.dart';

class BaseTransactionEntryCard extends ConsumerStatefulWidget {
  const BaseTransactionEntryCard({
    super.key,
    required this.hash,
    required this.type,
    required this.color,
    required this.icon,
    required this.timestamp,
    this.topoheight,
    this.url,
    this.isPending = false,
    this.nonce,
  });

  final String hash;
  final String type;
  final Color color;
  final IconData icon;
  final String timestamp;
  final String? topoheight;
  final Uri? url;
  final bool isPending;
  final BigInt? nonce;

  @override
  ConsumerState<BaseTransactionEntryCard> createState() =>
      _BaseTransactionEntryCardState();
}

class _BaseTransactionEntryCardState
    extends ConsumerState<BaseTransactionEntryCard> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final theme = context.theme;

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: theme.style.borderRadius.md,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: widget.color, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spaces.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spaces.medium,
              children: [
                Row(
                  spacing: Spaces.medium,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: Spaces.small,
                        children: [
                          Icon(widget.icon, color: widget.color, size: 20),
                          Flexible(
                            child: FBadge(
                              style: .delta(
                                decoration: .boxDelta(color: widget.color),
                              ),
                              child: Text(
                                widget.type.capitalize(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (widget.nonce != null)
                            Text(
                              '#${widget.nonce}',
                              style: theme.typography.body.sm.copyWith(
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          if (widget.isPending)
                            FBadge(
                              variant: .secondary,
                              child: Text(loc.pending),
                            ),
                        ],
                      ),
                    ),
                    if (widget.url case final url?)
                      FTooltip(
                        tipBuilder: (context, controller) {
                          return Text(loc.open_explorer);
                        },
                        child: FButton.icon(
                          semanticsTooltip: loc.open_explorer,
                          onPress: () => _launchUrl(url),
                          child: const Icon(FLucideIcons.externalLink),
                        ),
                      ),
                  ],
                ),
                FDivider(style: .delta(padding: .add(.zero))),
                Row(
                  spacing: Spaces.medium,
                  children: [
                    Expanded(
                      child: LabeledValue.text(loc.timestamp, widget.timestamp),
                    ),
                    if (widget.topoheight case final topoheight?)
                      Expanded(
                        child: LabeledValue.text(
                          loc.topoheight,
                          topoheight,
                          crossAxisAlignment: CrossAxisAlignment.end,
                        ),
                      ),
                  ],
                ),
                LabeledValue.child(
                  loc.hash,
                  Row(
                    spacing: Spaces.small,
                    children: [
                      Expanded(
                        child: FTooltip(
                          tipBuilder: (context, controller) =>
                              SelectableText(widget.hash),
                          child: Text(
                            truncateText(widget.hash, maxLength: 20),
                            style: theme.typography.body.md,
                          ),
                        ),
                      ),
                      FTooltip(
                        tipBuilder: (context, controller) => Text(loc.copy),
                        child: FButton.icon(
                          semanticsTooltip: loc.copy,
                          onPress: () =>
                              copyToClipboard(widget.hash, ref, loc.copied),
                          child: const Icon(FLucideIcons.copy, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: '${loc.launch_url_error} $url');
    }
  }
}
