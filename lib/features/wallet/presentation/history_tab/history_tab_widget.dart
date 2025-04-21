import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/filter_dialog.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/transaction_entry_widget.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  @override
  Widget build(BuildContext context) {
    ref.watch(searchQueryProvider);
    final loc = ref.watch(appLocalizationsProvider);
    final pagingState = ref.watch(historyPagingStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: Spaces.large,
            left: Spaces.large,
            right: Spaces.large,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.transactions, style: context.titleLarge),
              Tooltip(
                message: loc.filters,
                child: IconButton(
                  onPressed: () => _showFilterDialog(),
                  icon: Icon(Icons.filter_list_rounded),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: Spaces.small,
              left: Spaces.large,
              right: Spaces.large,
            ),
            child: RefreshIndicator(
              onRefresh:
                  () => Future.sync(
                    () => ref.invalidate(historyPagingStateProvider),
                  ),
              child: PagedListView<int, TransactionEntry>(
                state: pagingState,
                fetchNextPage: _fetchPage,
                builderDelegate: PagedChildBuilderDelegate<TransactionEntry>(
                  animateTransitions: true,
                  itemBuilder:
                      (context, item, index) =>
                          TransactionEntryWidget(transactionEntry: item),
                  noItemsFoundIndicatorBuilder:
                      (context) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.no_transactions_found,
                              style: context.titleLarge,
                            ),
                            const SizedBox(height: Spaces.medium),
                            FutureBuilder(
                              future: ref.read(historyCountProvider.future),
                              builder: (context, snapshot) {
                                if (snapshot.data != null &&
                                    snapshot.data! > 0) {
                                  return Text(
                                    loc.try_changing_filter,
                                    style: context.bodyMedium,
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _fetchPage() async {
    final state = ref.read(historyPagingStateProvider);

    if (state.isLoading) return;
    await Future<void>.value();
    ref.read(historyPagingStateProvider.notifier).loading();

    try {
      final newKey = (state.keys?.last ?? 0) + 1;
      talker.info('Fetching page: $newKey');
      final newItems = await ref.read(historyProvider(newKey).future);

      ref
          .read(historyPagingStateProvider.notifier)
          .setNextPage(newKey, newItems);
    } catch (error) {
      talker.error('Error fetching page: $error');
      ref.read(historyPagingStateProvider.notifier).error(error);
    }
  }

  void _showFilterDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FilterDialog();
      },
    ).then((isSaved) {
      if (isSaved != null && isSaved) {
        ref.invalidate(historyPagingStateProvider);
      }
    });
  }
}
