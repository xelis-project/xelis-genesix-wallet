import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/network_mismatch_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:intl/intl.dart';

class TopoHeightWidget extends ConsumerWidget {
  const TopoHeightWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    bool mismatch = ref.watch(networkMismatchProvider);
    final topoheight = ref.watch(
      walletStateProvider.select((state) => state.topoheight),
    );

    var displayedTopoheight = NumberFormat().format(topoheight);

    ValueNotifier<bool> isRescanningNotifier = ValueNotifier(false);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: GridTile(
          child: Row(
            children: [
              if (mismatch) ...[
                Tooltip(
                  message: loc.network_mismatch,
                  child: Icon(Icons.warning_amber, color: context.colors.error),
                ),
                const SizedBox(width: Spaces.medium),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.topoheight,
                    style: context.titleMedium /*!.copyWith(
                      color: context.moreColors.mutedColor,
                    ),*/,
                  ),
                  SelectableText(
                    displayedTopoheight,
                    style: context.headlineLarge,
                  ),
                ],
              ),
              const Spacer(),
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
                  const SizedBox(height: Spaces.extraSmall),
                  FittedBox(
                    fit: BoxFit.fitWidth,
                    child: Text(
                      loc.rescan,
                      maxLines: 1,
                      style: context.labelLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
