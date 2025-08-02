import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

class AddContactHeaderAction extends ConsumerWidget {
  const AddContactHeaderAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.all(Spaces.small),
      child: FTooltip(
        tipBuilder: (context, controller) => Text('Add Contact'),
        child: FHeaderAction(
          icon: Icon(FIcons.plus),
          onPress: () {
            // TODO: Implement add contact functionality
            print('add contact');
          },
        ),
      ),
    );
  }
}
