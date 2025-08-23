import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/features/wallet/presentation/components/colored_badge.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/sheet_content.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class ExtraDataSheet extends ConsumerStatefulWidget {
  const ExtraDataSheet({super.key, required this.parsed, this.showKey = false});

  final ParsedExtraData parsed;
  final bool showKey;

  @override
  ConsumerState createState() => _ExtraDataSheetState();
}

class _ExtraDataSheetState extends ConsumerState<ExtraDataSheet> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final keyPart = (widget.showKey && widget.parsed.sharedKeyRedacted != null)
        ? Text(' • ${loc.key}: ${widget.parsed.sharedKeyRedacted}')
        : const SizedBox.shrink();

    return SheetContent(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spaces.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.smallMedium,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: Spaces.small,
                  runSpacing: Spaces.small,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ColoredBadge.flag(widget.parsed.flag),
                    ColoredBadge.label(widget.parsed.label),
                    Text(
                      '• ${widget.parsed.fmtSize}',
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    keyPart,
                  ],
                ),
                FTooltip(
                  tipBuilder: (context, controller) => Text(loc.copy),
                  child: FButton.icon(
                    onPress: () => copyToClipboard(
                      widget.parsed.copyText,
                      ref,
                      loc.copied,
                    ),
                    child: const Icon(FIcons.copy),
                  ),
                ),
              ],
            ),
            FCard(
              child: Center(
                child: SelectableText(
                  widget.parsed.pretty,
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (widget.parsed.flag == Flag.failed) ...[
              Text(
                "Note: this extra data is marked as 'failed' (likely decode error).", // TODO localize
              ),
            ],
          ],
        ),
      ),
    );
  }
}
