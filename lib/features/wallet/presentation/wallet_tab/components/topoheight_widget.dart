import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:intl/intl.dart';

class TopoHeightWidget extends ConsumerWidget {
  const TopoHeightWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final topoheight =
        ref.watch(walletStateProvider.select((state) => state.topoheight));

    ValueNotifier<bool> isRescanningNotifier = ValueNotifier(false);
    var displayTopo = NumberFormat().format(topoheight);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: GridTile(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.topoheight,
                  style: context.titleMedium!
                      .copyWith(color: context.moreColors.mutedColor),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: AppDurations.animFast),
                  child: SelectableText(
                    key: ValueKey<String>(displayTopo),
                    displayTopo,
                    style: context.headlineLarge,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: isRescanningNotifier,
                  builder:
                      (BuildContext context, bool isRescanning, Widget? _) {
                    return IconButton.outlined(
                      onPressed: isRescanning
                          ? null
                          : () async {
                              isRescanningNotifier.value = true;
                              await ref
                                  .read(walletStateProvider.notifier)
                                  .rescan();
                              isRescanningNotifier.value = false;
                            },
                      icon: const Icon(Icons.sync_rounded),
                    );
                  },
                ),
                FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Text(
                    loc.rescan,
                    maxLines: 1,
                    style: context.labelMedium,
                  ),
                ),
              ],
            ),
          ],
        )),
      ),
    );
  }
}
