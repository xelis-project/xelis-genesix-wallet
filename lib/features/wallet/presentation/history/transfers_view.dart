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
    required this.loc,
    required this.rows,
    this.fromAddress,
    this.fee,
    this.summaryCard,
  }) : mode = TransferDirection.incoming;

  const TransfersView.outgoing({
    super.key,
    required this.loc,
    required this.rows,
    this.fromAddress,
    this.fee,
    this.summaryCard,
  }) : mode = TransferDirection.outgoing;

  final AppLocalizations loc;
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
          Row(children: [LabeledValue.text(loc.fee, fee!), Spacer()]),
        if (fromAddress != null)
          LabeledValue.child(loc.from, AddressWidget(fromAddress!)),
        if (summaryCard != null) ...[summaryCard!],
        const SizedBox(height: Spaces.medium),
        Row(
          children: [
            Expanded(child: FDivider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
              child: Text(
                loc.transfers,
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
            Expanded(child: FDivider()),
          ],
        ),
        if (context.isWideScreen)
          _WideTable(loc: loc, rows: rows, mode: mode)
        else
          _NarrowList(loc: loc, rows: rows),
      ],
    );
  }
}

class _NarrowList extends ConsumerWidget {
  const _NarrowList({required this.rows, required this.loc});

  final List<TransferEntryRow> rows;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideExtraData = ref.watch(
      settingsProvider.select(
        (value) => value.historyFilterState.hideExtraData,
      ),
    );

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
                          loc.destination,
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
                    loc.asset,
                    FBadge(variant: .outline, child: Text(row.asset)),
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                  LabeledValue.text(
                    loc.amount.capitalize(),
                    row.amountText,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
                ],
              ),
              if (row.extra != null)
                LabeledValue.child(
                  loc.extra_data.capitalizeAll(),
                  hideExtraData
                      ? FBadge(variant: .secondary, child: Text(loc.hidden))
                      : ExtraDataIndicator(
                          extra: row.extra,
                          onOpen: () =>
                              _openExtraSheet(context, loc, row.extra!),
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
  _WideTable({required this.loc, required this.rows, required this.mode});

  final AppLocalizations loc;
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

    return FadedScroll(
      axis: Axis.horizontal,
      controller: _controller,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: switch (mode) {
            TransferDirection.incoming => [
              _transfersDataColumn(context, loc.asset),
              _transfersDataColumn(context, loc.amount.capitalize()),
              _transfersDataColumn(context, loc.extra_data.capitalizeAll()),
            ],
            TransferDirection.outgoing => [
              _transfersDataColumn(context, loc.asset),
              _transfersDataColumn(context, loc.amount.capitalize()),
              _transfersDataColumn(context, loc.destination),
              _transfersDataColumn(context, loc.extra_data.capitalizeAll()),
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
                          variant: .outline,
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
                                variant: .secondary,
                                child: Text(loc.hidden),
                              )
                            : ExtraDataIndicator(
                                extra: row.extra,
                                onOpen: () =>
                                    _openExtraSheet(context, loc, row.extra!),
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
                          variant: .outline,
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
                                variant: .secondary,
                                child: Text(loc.hidden),
                              )
                            : ExtraDataIndicator(
                                extra: row.extra,
                                onOpen: () =>
                                    _openExtraSheet(context, loc, row.extra!),
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
