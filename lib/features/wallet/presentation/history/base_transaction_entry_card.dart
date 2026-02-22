import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class BaseTransactionEntryCard extends ConsumerStatefulWidget {
  const BaseTransactionEntryCard({
    super.key,
    required this.transactionEntry,
    required this.type,
    required this.color,
    required this.timestamp,
    required this.topoheight,
    required this.url,
    this.nonce,
  });

  final TransactionEntry transactionEntry;
  final String type;
  final Color color;
  final String timestamp;
  final String topoheight;
  final Uri url;
  final int? nonce;

  @override
  ConsumerState<BaseTransactionEntryCard> createState() =>
      _BaseTransactionEntryCardState();
}

class _BaseTransactionEntryCardState
    extends ConsumerState<BaseTransactionEntryCard> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            if (widget.nonce != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${widget.nonce}',
                    style: context.theme.typography.base,
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FBadge(
                  style: .delta(decoration: .delta(color: widget.color)),
                  child: Text(widget.type.capitalize()),
                ),
                FTooltip(
                  tipBuilder: (context, controller) {
                    return Text(loc.open_explorer);
                  },
                  child: FButton.icon(
                    onPress: () => _launchUrl(widget.url),
                    child: Icon(FIcons.link),
                  ),
                ),
              ],
            ),
            LabeledValue.text(loc.timestamp, widget.timestamp),
            LabeledValue.text(loc.topoheight, widget.topoheight),
            LabeledValue.text(loc.hash, widget.transactionEntry.hash),
          ],
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
