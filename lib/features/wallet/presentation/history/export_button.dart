import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/features/wallet/presentation/history/filters_dialog.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

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
          icon: Icon(FLucideIcons.download),
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
    final walletCommands = ref.read(walletCommandsProvider);
    final toast = ref.read(toastProvider.notifier);
    String? exportDirectory;

    try {
      final historyFilter = wallet_flutter.XelisWalletHistoryFilter(
        page: BigInt.one,
        limit: null, // Export all transactions
        assetHash: filterState.asset,
        destination: filterState.address == null
            ? null
            : wallet_flutter.XelisWalletFlutter.parseAddress(
                address: filterState.address!,
              ),
        minTopoheight: null,
        maxTopoheight: null,
        acceptIncoming: filterState.showIncoming,
        acceptOutgoing: filterState.showOutgoing,
        acceptCoinbase: filterState.showCoinbase,
        acceptBurn: filterState.showBurn,
        acceptBlob: filterState.showBlob,
        minTimestampMillis: filterState.minTimestamp != null
            ? BigInt.from(filterState.minTimestamp!.millisecondsSinceEpoch)
            : null,
        maxTimestampMillis: filterState.maxTimestamp != null
            ? BigInt.from(filterState.maxTimestamp!.millisecondsSinceEpoch)
            : null,
      );

      if (kIsWeb) {
        final csv = await walletCommands.exportCsvForWeb(historyFilter);
        saveTextFile(csv, 'genesix_transactions.csv');
      } else {
        exportDirectory = await FilePicker.getDirectoryPath();
        if (exportDirectory == null) return;
        await walletCommands.exportCsv(exportDirectory, historyFilter);
      }

      if (!mounted) return;
      toast.showInformation(title: loc.csv_exported_successfully);
    } catch (error, stackTrace) {
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.history.csv.export',
        applicationCode: 'wallet_history_csv_export_failed',
        contextBuilder: exportDirectory == null
            ? null
            : () => 'exportDirectory=$exportDirectory',
      );
      if (!mounted) return;
      toast.showFailure(title: loc.error_exporting_csv, failure: failure);
    }
  }
}
