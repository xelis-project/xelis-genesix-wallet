import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/features/wallet/presentation/components/colored_badge.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_indicator.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_sheet.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class BlobEntryContent extends ConsumerWidget {
  const BlobEntryContent(this.blobEntry, {super.key});

  final BlobEntry blobEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final hideExtraData = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideExtraData,
      ),
    );
    final parsed = ParsedExtraData.parse(loc, blobEntry.data);

    return FCard.raw(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            Wrap(
              spacing: Spaces.small,
              runSpacing: Spaces.small,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ColoredBadge.flag(parsed.flag),
                ColoredBadge.label(parsed.label),
                Text(
                  '• ${parsed.fmtSize}',
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            LabeledValue.child(
              loc.extra_data.capitalizeAll(),
              hideExtraData
                  ? FBadge(variant: .secondary, child: Text(loc.hidden))
                  : ExtraDataIndicator(
                      extra: blobEntry.data,
                      onOpen: () =>
                          _openExtraSheet(context, loc, blobEntry.data),
                    ),
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            if (parsed.flag == Flag.failed) Text(loc.extra_data_decode_failed),
          ],
        ),
      ),
    );
  }
}

void _openExtraSheet(
  BuildContext context,
  AppLocalizations loc,
  ExtraData extra,
) {
  showFSheet<void>(
    context: context,
    side: FLayout.btt,
    useRootNavigator: true,
    mainAxisMaxRatio: context.getFSheetRatio,
    builder: (context) =>
        ExtraDataSheet(parsed: ParsedExtraData.parse(loc, extra)),
  );
}
