import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/assets/tracked_assets_tab.dart';
import 'package:genesix/features/wallet/presentation/assets/untracked_assets_tab.dart';

class AssetsContent extends ConsumerWidget {
  const AssetsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double height = constraints.maxHeight;

        return FTabs(
          children: [
            FTabEntry(
              label: Text(loc.tracked, textAlign: TextAlign.center),
              child: TrackedAssetsTab(height),
            ),
            FTabEntry(
              label: Text(loc.untracked, textAlign: TextAlign.center),
              child: UntrackedAssetsTab(height),
            ),
          ],
        );
      },
    );
  }
}
