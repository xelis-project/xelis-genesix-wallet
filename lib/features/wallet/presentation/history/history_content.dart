import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/presentation/history/transaction_grouped_widget.dart';
import 'package:genesix/features/wallet/presentation/transaction_view_utils.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/custom_skeletonizer.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class HistoryContent extends ConsumerStatefulWidget {
  const HistoryContent({super.key});

  @override
  ConsumerState createState() => _HistoryContentState();
}

class _HistoryContentState extends ConsumerState<HistoryContent> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final pagingState = ref.watch(historyPagingStateProvider);

    return PagedListView<int, MapEntry<DateTime, List<TransactionEntry>>>(
      state: pagingState,
      fetchNextPage: _fetchPage,
      builderDelegate:
          PagedChildBuilderDelegate<MapEntry<DateTime, List<TransactionEntry>>>(
            animateTransitions: true,
            itemBuilder: (context, item, index) =>
                TransactionGroupedWidget(item),
            noItemsFoundIndicatorBuilder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.no_transactions_found,
                    style: context.theme.typography.base.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: Spaces.medium),
                  FutureBuilder(
                    future: ref.read(historyCountProvider.future),
                    builder: (context, snapshot) {
                      if (snapshot.data != null && snapshot.data! > 0) {
                        return Text(
                          loc.try_changing_filter,
                          style: context.theme.typography.base.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
            ),
            // firstPageProgressIndicatorBuilder: (context) =>
            //     SingleChildScrollView(
            //       child: CustomSkeletonizer(
            //         child: Column(
            //           children: List.generate(
            //             30,
            //             (index) => FItem(
            //               title: Text('Dummy label'),
            //               subtitle: Text('Dummy subtitle'),
            //               details: Text('Dummy details'),
            //               prefix: const Icon(FIcons.history),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
          ),
    );
  }

  void _fetchPage() async {
    final state = ref.read(historyPagingStateProvider);

    if (state.isLoading) return;
    await Future<void>.value();
    ref.read(historyPagingStateProvider.notifier).loading();

    try {
      final newPage = (state.keys?.last ?? 0) + 1;
      talker.info('Fetching page: $newPage');
      final transactions = await ref.read(historyProvider(newPage).future);

      final grouped = groupTransactionsByDateSorted2Levels(transactions);

      ref
          .read(historyPagingStateProvider.notifier)
          .setNextPage(newPage, grouped.entries.toList());
    } catch (error) {
      talker.error('Error fetching page: $error');
      ref.read(historyPagingStateProvider.notifier).error(error);
    }
  }
}
