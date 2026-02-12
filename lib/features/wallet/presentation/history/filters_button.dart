import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/domain/history_filter_state.dart';
import 'package:genesix/features/wallet/presentation/history/filters_dialog.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';

class FiltersButton extends ConsumerStatefulWidget {
  const FiltersButton({super.key});

  @override
  ConsumerState<FiltersButton> createState() => _FiltersButtonState();
}

class _FiltersButtonState extends ConsumerState<FiltersButton> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.all(Spaces.small),
      child: FTooltip(
        tipBuilder: (context, controller) => Text(loc.filters),
        child: FHeaderAction(
          onPress: _showFilterDialog,
          icon: Icon(FIcons.listFilter),
        ),
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final addressBook = await ref.read(addressBookProvider.future);

    if (!mounted) return;

    showAppDialog<HistoryFilterState>(
      context: context,
      builder: (context, style, animation) => FiltersDialog(addressBook),
    ).then((filterState) {
      if (filterState != null) {
        ref.invalidate(historyPagingStateProvider);
      }
    });
  }
}
