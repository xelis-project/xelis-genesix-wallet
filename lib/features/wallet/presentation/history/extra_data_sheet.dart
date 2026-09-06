import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/features/wallet/presentation/components/colored_badge.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/sheet_content.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class ExtraDataSheet extends ConsumerStatefulWidget {
  ExtraDataSheet({super.key, required ParsedExtraData parsed})
    : _content = _HistoryExtraDataSheetContent(parsed);

  /// Displays a typed payload revealed by an explicit user action.
  ///
  /// No history flag is invented. [source] and [encrypted] are optional
  /// metadata supplied by the capability-bound prepared inspection. An
  /// integrated-address detail can instead set [visibleInAddress].
  ExtraDataSheet.typed({
    super.key,
    required XelisDataElement data,
    XelisWalletPreparedExtraDataSource? source,
    bool? encrypted,
    bool visibleInAddress = false,
  }) : _content = _TypedExtraDataSheetContent(
         data: data,
         source: source,
         encrypted: encrypted,
         visibleInAddress: visibleInAddress,
       );

  final _ExtraDataSheetContent _content;

  @override
  ConsumerState createState() => _ExtraDataSheetState();
}

class _ExtraDataSheetState extends ConsumerState<ExtraDataSheet> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final _ResolvedExtraDataSheetContent content = switch (widget._content) {
      _HistoryExtraDataSheetContent(:final parsed) => (
        parsed: parsed,
        data: null,
        source: null,
        encrypted: null,
        visibleInAddress: false,
      ),
      _TypedExtraDataSheetContent(
        :final data,
        :final source,
        :final encrypted,
        :final visibleInAddress,
      ) =>
        (
          parsed: null,
          data: data,
          source: source,
          encrypted: encrypted,
          visibleInAddress: visibleInAddress,
        ),
    };
    final typed = switch (content.data) {
      final data? => ParsedXelisDataElement.parse(loc, data),
      null => null,
    };
    final label = content.parsed?.label ?? typed!.label;
    final fmtSize = content.parsed?.fmtSize ?? typed?.fmtSize;
    final pretty = content.parsed?.pretty ?? typed!.pretty;
    final copyText = content.parsed?.copyText ?? typed!.copyText;

    return SheetContent(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spaces.small),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Spaces.smallMedium,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: Spaces.small,
                    runSpacing: Spaces.small,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (content.parsed case final parsed?)
                        ColoredBadge.flag(parsed.flag),
                      ColoredBadge.label(label),
                      if (content.source case final source?)
                        FBadge(
                          variant: .outline,
                          child: Text(
                            '${loc.attached_data_source}: '
                            '${_sourceLabel(loc, source)}',
                          ),
                        ),
                      if (content.encrypted case final encrypted?)
                        FBadge(
                          variant: .secondary,
                          child: Text(
                            encrypted
                                ? loc.attached_data_encrypted
                                : loc.attached_data_not_encrypted,
                          ),
                        ),
                      if (content.visibleInAddress)
                        FBadge(
                          variant: .outline,
                          child: Text(
                            loc.receive_integrated_address_data_visible,
                          ),
                        ),
                      if (fmtSize case final size?)
                        Text(
                          '• $size',
                          style: context.theme.typography.body.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                if (copyText.isNotEmpty) ...[
                  const SizedBox(width: Spaces.small),
                  FTooltip(
                    tipBuilder: (context, controller) => Text(loc.copy),
                    child: FButton.icon(
                      semanticsTooltip: loc.copy,
                      onPress: () => copyToClipboard(copyText, ref, loc.copied),
                      child: const Icon(FLucideIcons.copy),
                    ),
                  ),
                ],
              ],
            ),
            if (content.visibleInAddress)
              Text(
                loc.receive_integrated_address_data_visible_description,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            AppCard(
              clipBehavior: Clip.antiAlias,
              child: Center(
                child: SelectableText(
                  pretty,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (content.parsed?.flag == XelisWalletExtraDataFlag.failed)
              Text(loc.extra_data_decode_failed),
          ],
        ),
      ),
    );
  }
}

sealed class _ExtraDataSheetContent {
  const _ExtraDataSheetContent();
}

final class _HistoryExtraDataSheetContent extends _ExtraDataSheetContent {
  const _HistoryExtraDataSheetContent(this.parsed);

  final ParsedExtraData parsed;
}

final class _TypedExtraDataSheetContent extends _ExtraDataSheetContent {
  const _TypedExtraDataSheetContent({
    required this.data,
    required this.source,
    required this.encrypted,
    required this.visibleInAddress,
  });

  final XelisDataElement data;
  final XelisWalletPreparedExtraDataSource? source;
  final bool? encrypted;
  final bool visibleInAddress;
}

typedef _ResolvedExtraDataSheetContent = ({
  ParsedExtraData? parsed,
  XelisDataElement? data,
  XelisWalletPreparedExtraDataSource? source,
  bool? encrypted,
  bool visibleInAddress,
});

String _sourceLabel(
  AppLocalizations loc,
  XelisWalletPreparedExtraDataSource source,
) => switch (source) {
  XelisWalletPreparedExtraDataSource.integratedAddress =>
    loc.attached_data_source_integrated_address,
  XelisWalletPreparedExtraDataSource.explicit =>
    loc.attached_data_source_explicit,
};
