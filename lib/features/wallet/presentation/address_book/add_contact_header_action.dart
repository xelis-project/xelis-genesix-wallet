import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_sheet.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';

class AddContactHeaderAction extends ConsumerStatefulWidget {
  const AddContactHeaderAction({super.key});

  @override
  ConsumerState<AddContactHeaderAction> createState() =>
      _AddContactHeaderActionState();
}

class _AddContactHeaderActionState
    extends ConsumerState<AddContactHeaderAction> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.all(Spaces.small),
      child: FTooltip(
        tipBuilder: (context, controller) => Text('Add Contact'),
        child: FHeaderAction(
          icon: Icon(FIcons.plus),
          onPress: _showAddContactSheet,
        ),
      ),
    );
  }

  void _showAddContactSheet() {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.getFSheetRatio,
      builder: (context) => AddContactSheet(),
    );
  }
}
