import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/features/wallet/domain/transfer_entry_row.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_indicator.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_sheet.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class TransfersView extends StatelessWidget {
  const TransfersView.incoming({
    super.key,
    required this.localizations,
    required this.rows,
    this.fromAddress,
    this.fee,
    this.summaryCard,
  }) : mode = TransferDirection.incoming;

  const TransfersView.outgoing({
    super.key,
    required this.localizations,
    required this.rows,
    this.fromAddress,
    this.fee,
    this.summaryCard,
  }) : mode = TransferDirection.outgoing;

  final AppLocalizations localizations;
  final List<TransferEntryRow> rows;
  final TransferDirection mode;
  final String? fromAddress;
  final String? fee;
  final Widget? summaryCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (fee != null)
          Row(children: [LabeledValue.text(localizations.fee, fee!), Spacer()]),
        if (fromAddress != null)
          LabeledValue.child(localizations.from, AddressWidget(fromAddress!)),
        if (summaryCard != null) ...[summaryCard!],
        const SizedBox(height: Spaces.medium),
        Row(
          children: [
            Expanded(child: FDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
              child: Text(
                localizations.transfers,
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
            Expanded(child: FDivider()),
          ],
        ),
        if (context.isWideScreen)
          _WideTable(localizations: localizations, rows: rows, mode: mode)
        else
          _NarrowList(localizations: localizations, rows: rows),
      ],
    );
  }
}

class _NarrowList extends ConsumerWidget {
  const _NarrowList({required this.rows, required this.localizations});

  final List<TransferEntryRow> rows;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideExtraData = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideExtraData,
      ),
    );

    final loc = AppLocalizations.of(context);

    return FItemGroup.builder(
      count: rows.length,
      divider: FItemDivider.indented,
      itemBuilder: (context, index) {
        final row = rows[index];

        return FItem.raw(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spaces.small,
            children: [
              if (row.destination != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (row.destination != null)
                      Expanded(
                        child: LabeledValue.child(
                          localizations.destination,
                          AddressWidget(row.destination!),
                        ),
                      ),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledValue.child(
                    localizations.asset,
                    FBadge(
                      style: FBadgeStyle.outline(),
                      child: Text(row.asset),
                    ),
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                  LabeledValue.text(
                    localizations.amount.capitalize(),
                    row.amountText,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ],
              ),
              if (row.extra != null)
                LabeledValue.child(
                  localizations.extra_data.capitalizeAll(),
                  hideExtraData
                      ? FBadge(
                          style: FBadgeStyle.secondary(),
                          child: Text(loc.hidden),
                        )
                      : ExtraDataIndicator(
                          extra: row.extra,
                          onOpen: () => _openExtraSheet(context, row.extra!),
                        ),
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WideTable extends ConsumerWidget {
  _WideTable({
    required this.localizations,
    required this.rows,
    required this.mode,
  });

  final AppLocalizations localizations;
  final List<TransferEntryRow> rows;
  final TransferDirection mode;

  final _controller = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideExtraData = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideExtraData,
      ),
    );

    final loc = AppLocalizations.of(context);

    return FadedScroll(
      axis: Axis.horizontal,
      controller: _controller,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: switch (mode) {
            TransferDirection.incoming => [
              _transfersDataColumn(context, localizations.asset),
              _transfersDataColumn(context, localizations.amount.capitalize()),
              _transfersDataColumn(
                context,
                localizations.extra_data.capitalizeAll(),
              ),
            ],
            TransferDirection.outgoing => [
              _transfersDataColumn(context, localizations.asset),
              _transfersDataColumn(context, localizations.amount.capitalize()),
              _transfersDataColumn(context, localizations.destination),
              _transfersDataColumn(
                context,
                localizations.extra_data.capitalizeAll(),
              ),
            ],
          },
          rows: rows.map((row) {
            switch (mode) {
              case TransferDirection.incoming:
                return DataRow(
                  cells: [
                    DataCell(
                      Center(
                        child: FBadge(
                          style: FBadgeStyle.outline(),
                          child: Text(row.asset),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: SelectableText(
                          row.amountText,
                          style: context.theme.typography.base,
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: hideExtraData
                            ? FBadge(
                                style: FBadgeStyle.secondary(),
                                child: Text(loc.hidden),
                              )
                            : ExtraDataIndicator(
                                extra: row.extra,
                                onOpen: () =>
                                    _openExtraSheet(context, row.extra!),
                              ),
                      ),
                    ),
                  ],
                );
              case TransferDirection.outgoing:
                return DataRow(
                  cells: [
                    DataCell(
                      Center(
                        child: FBadge(
                          style: FBadgeStyle.outline(),
                          child: Text(row.asset),
                        ),
                      ),
                    ),
                    DataCell(Center(child: SelectableText(row.amountText))),
                    DataCell(
                      Center(
                        child: Text(
                          truncateText(row.destination!, maxLength: 20),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: hideExtraData
                            ? FBadge(
                                style: FBadgeStyle.secondary(),
                                child: Text(loc.hidden),
                              )
                            : ExtraDataIndicator(
                                extra: row.extra,
                                onOpen: () =>
                                    _openExtraSheet(context, row.extra!),
                              ),
                      ),
                    ),
                  ],
                );
            }
          }).toList(),
        ),
      ),
    );
  }

  DataColumn _transfersDataColumn(BuildContext context, String label) {
    return DataColumn(
      headingRowAlignment: MainAxisAlignment.center,
      label: Text(
        label,
        style: context.theme.typography.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

void _openExtraSheet(BuildContext context, ExtraData extra) {
  showFSheet<void>(
    context: context,
    side: FLayout.btt,
    useRootNavigator: true,
    mainAxisMaxRatio: context.getFSheetRatio,
    builder: (context) => ExtraDataSheet(parsed: ParsedExtraData.parse(extra)),
  );
}
