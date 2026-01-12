import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/history/transaction_grouped_widget.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class HistoryContent extends ConsumerStatefulWidget {
  const HistoryContent({super.key});

  @override
  ConsumerState createState() => _HistoryContentState();
}

class _HistoryContentState extends ConsumerState<HistoryContent> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final pagingState = ref.watch(historyPagingStateProvider);

    if (ref.watch(walletStateProvider.select((s) => s.isRescanning))) {
      return Center(child: FCircularProgress());
    }

    final addressBook = ref.watch(addressBookProvider);

    switch (addressBook) {
      case AsyncData(:final value):
        return FadedScroll(
          controller: _controller,
          fadeFraction: 0.08,
          child: PagedListView<int, MapEntry<DateTime, List<TransactionEntry>>>(
            scrollController: _controller,
            state: pagingState,
            fetchNextPage: _fetchPage,
            builderDelegate:
                PagedChildBuilderDelegate<
                  MapEntry<DateTime, List<TransactionEntry>>
                >(
                  animateTransitions: true,
                  itemBuilder: (context, item, index) =>
                      TransactionGroupedWidget(
                        item,
                        value,
                        key: ValueKey(item.key),
                      ),
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
                  firstPageProgressIndicatorBuilder: null,
                ),
          ),
        );
      case AsyncError():
        return Center(
          child: Text(
            loc.oups,
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.error,
            ),
          ),
        );
      default:
        return Center(child: FCircularProgress());
    }
  }

  void _fetchPage() async {
    final pagingNotifier = ref.read(historyPagingStateProvider.notifier);
    final state = ref.read(historyPagingStateProvider);

    if (state.isLoading) return;

    await Future<void>.value();
    pagingNotifier.loading();

    try {
      final newPage = (state.keys?.last ?? 0) + 1;
      talker.info('Fetching page: $newPage');
      final transactions = await ref.read(historyProvider(newPage).future);

      final grouped = groupTransactionsByDateSorted2Levels(transactions);

      pagingNotifier.setNextPage(newPage, grouped.entries.toList());
    } catch (error) {
      talker.error('Error fetching page: $error');
      pagingNotifier.error(error);
    }
  }
}
