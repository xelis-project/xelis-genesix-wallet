import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/components/colored_badge.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_indicator.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_sheet.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class BlobEntryContent extends ConsumerWidget {
  BlobEntryContent.incoming(XelisWalletIncomingBlobEntry blobEntry, {super.key})
    : data = blobEntry.data,
      from = blobEntry.from,
      destinations = blobEntry.destinations,
      fee = null,
      exactDestinations = const [];

  BlobEntryContent.outgoing(
    XelisWalletOutgoingBlobEntry blobEntry, {
    this.exactDestinations = const [],
    super.key,
  }) : data = blobEntry.data,
       from = null,
       destinations = blobEntry.destinations,
       fee = blobEntry.fee;

  final XelisWalletExtraData data;
  final String? from;
  final List<String> destinations;
  final BigInt? fee;
  final List<XelisAddressBookEntry?> exactDestinations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final hideExtraData = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideExtraData,
      ),
    );
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );
    final parsed = ParsedExtraData.parse(loc, data);

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.medium,
          children: [
            if (fee != null)
              LabeledValue.text(loc.fee, formatXelis(fee!, network)),
            if (from != null)
              LabeledValue.child(loc.from, AddressWidget(from!)),
            for (final item in destinations.indexed)
              LabeledValue.child(
                loc.destination,
                _BlobDestinationValue(
                  destination: item.$2,
                  exactDestination: item.$1 < exactDestinations.length
                      ? exactDestinations[item.$1]
                      : null,
                ),
              ),
            Wrap(
              spacing: Spaces.small,
              runSpacing: Spaces.small,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ColoredBadge.flag(parsed.flag),
                ColoredBadge.label(parsed.label),
                if (parsed.fmtSize case final size?)
                  Text(
                    '• $size',
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
                      extra: data,
                      onOpen: () => _openExtraSheet(context, loc, data),
                    ),
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            if (parsed.flag == XelisWalletExtraDataFlag.failed)
              Text(loc.extra_data_decode_failed),
          ],
        ),
      ),
    );
  }
}

class _BlobDestinationValue extends StatelessWidget {
  const _BlobDestinationValue({
    required this.destination,
    required this.exactDestination,
  });

  final String destination;
  final XelisAddressBookEntry? exactDestination;

  @override
  Widget build(BuildContext context) {
    final canonicalDestination = exactDestination?.destination.address;
    if (canonicalDestination != null) {
      return AddressWidget(canonicalDestination);
    }

    return FTooltip(
      tipBuilder: (context, controller) => SelectableText(destination),
      child: SelectableText(
        destination,
        style: context.theme.typography.body.md,
      ),
    );
  }
}

void _openExtraSheet(
  BuildContext context,
  AppLocalizations loc,
  XelisWalletExtraData extra,
) {
  showFSheet<void>(
    context: context,
    side: FLayout.btt,
    useRootNavigator: true,
    mainAxisMaxRatio: context.responsiveSheetMaxRatio,
    builder: (context) =>
        ExtraDataSheet(parsed: ParsedExtraData.parse(loc, extra)),
  );
}
