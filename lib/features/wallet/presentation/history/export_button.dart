import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';

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
        child: FHeaderAction(onPress: _exportCSV, icon: Icon(FIcons.download)),
      ),
    );
  }

  Future<void> _exportCSV() async {
    if (!mounted) return;

    final loc = ref.read(appLocalizationsProvider);
    final wallet = ref.read(walletStateProvider.notifier);
    final toast = ref.read(toastProvider.notifier);
    toast.showEvent(description: 'Exporting wallet transactions...');

    if (kIsWeb) {
      final content = await wallet.exportCsvForWeb();
      if (content != null) {
        saveTextFile(content, 'genesix_transactions.csv');
        toast.showInformation(title: loc.csv_exported_successfully);
      } else {
        toast.showError(description: loc.error_exporting_csv);
      }
    } else {
      var path = await FilePicker.platform.getDirectoryPath();
      if (path != null) {
        try {
          await wallet.exportCsv(path);
          toast.showInformation(title: loc.csv_exported_successfully);
        } catch (error) {
          talker.error('Error exporting csv: $error');
          toast.showError(description: loc.error_exporting_csv);
        }
      }
    }
  }
}
