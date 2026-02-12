import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/features/wallet/presentation/history/filters_dialog.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';

class ExportButton extends ConsumerStatefulWidget {
  const ExportButton({super.key});

  @override
  ConsumerState<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<ExportButton> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.all(Spaces.small),
      child: FTooltip(
        tipBuilder: (context, controller) => Text(loc.export_csv_tooltip),
        child: FHeaderAction(
          onPress: _showExportFiltersDialog,
          icon: Icon(FIcons.download),
        ),
      ),
    );
  }

  Future<void> _showExportFiltersDialog() async {
    final addressBook = await ref.read(addressBookProvider.future);

    if (!mounted) return;

    showAppDialog<HistoryFilterState>(
      context: context,
      builder: (context, style, animation) => FiltersDialog(
        addressBook,
        title: ref.read(appLocalizationsProvider).export_csv_tooltip,
        applyLabel: ref.read(appLocalizationsProvider).export_csv_tooltip,
      ),
    ).then((filterState) {
      if (filterState != null) {
        _exportCSV(filterState);
      }
    });
  }

  Future<void> _exportCSV(HistoryFilterState filterState) async {
    if (!mounted) return;

    final loc = ref.read(appLocalizationsProvider);
    final walletNotifier = ref.read(walletStateProvider.notifier);
    final toast = ref.read(toastProvider.notifier);
    toast.showEvent(description: 'Exporting wallet transactions...');

    try {
      final historyPageFilter = HistoryPageFilter(
        page: BigInt.from(1),
        limit: null, // Export all transactions
        assetHash: filterState.asset,
        address: filterState.address,
        minTopoheight: null,
        maxTopoheight: null,
        acceptIncoming: filterState.showIncoming,
        acceptOutgoing: filterState.showOutgoing,
        acceptCoinbase: filterState.showCoinbase,
        acceptBurn: filterState.showBurn,
        minTimestamp: filterState.minTimestamp != null
            ? BigInt.from(filterState.minTimestamp!.millisecondsSinceEpoch)
            : null,
        maxTimestamp: filterState.maxTimestamp != null
            ? BigInt.from(filterState.maxTimestamp!.millisecondsSinceEpoch)
            : null,
      );

      if (kIsWeb) {
        final csv = await walletNotifier.exportCsvForWeb(historyPageFilter);
        if (csv != null) {
          saveTextFile(csv, 'genesix_transactions.csv');
          toast.showInformation(title: loc.csv_exported_successfully);
        } else {
          toast.showError(description: loc.error_exporting_csv);
        }
      } else {
        var path = await FilePicker.platform.getDirectoryPath();
        if (path != null) {
          await walletNotifier.exportCsv(path, historyPageFilter);
          toast.showInformation(title: loc.csv_exported_successfully);
        }
      }
    } catch (e, stack) {
      talker.handle(e, stack);
      toast.showError(
        title: loc.error_exporting_csv,
        description: e.toString(),
      );
    }
  }
}
