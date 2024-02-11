import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Text(
        'HISTORY TAB',
        style: context.displayMedium,
      ),
    );

    // final asyncData = ref.watch(walletHistoryProvider);
    // return asyncData.when(
    //   skipLoadingOnReload: true,
    //   data: (history) {
    //     // TODO AnimatedSwitcher
    //     return ListView.builder(
    //       itemCount: history.length,
    //       itemBuilder: (context, index) {
    //         return HistoryEntry(
    //           txEntry: history[index],
    //         );
    //       },
    //     );
    //   },
    //   error: (error, stackTrace) => Center(child: Text(error.toString())),
    //   loading: () => Center(
    //     child: LoadingAnimationWidget.waveDots(
    //       color: context.colors.primary,
    //       size: 20,
    //     ),
    //   ),
    // );
  }
}
