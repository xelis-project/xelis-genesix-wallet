import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/filter_dialog.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/transaction_entry_widget.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/src/generated/rust_bridge/api/utils.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  static const _pageSize = 10;

  final PagingController<int, TransactionEntry> _pagingController =
      PagingController(firstPageKey: 1);
  final GlobalKey<FormBuilderState> _searchFormKey =
      GlobalKey<FormBuilderState>();
  final _searchFocusNode = FocusNode();

  String searchQuery = '';
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    ref.listenManual(walletStateProvider.select((state) => state.assets), (
      _,
      _,
    ) {
      _pagingController.refresh();
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final searchBar = Padding(
      padding: const EdgeInsets.only(
        left: Spaces.extraSmall,
        bottom: Spaces.large,
      ),
      child: FormBuilder(
        key: _searchFormKey,
        child: FormBuilderTextField(
          name: 'searchQuery',
          focusNode: _searchFocusNode,
          decoration: context.textInputDecoration.copyWith(
            labelText: loc.search_transaction_by_address,
            suffixIcon: IconButton(
              hoverColor: Colors.transparent,
              onPressed: _onSearchQueryClear,
              icon: Icon(
                Icons.clear,
                size: 18,
                color: context.moreColors.mutedColor,
              ),
            ),
          ),
          onChanged: _onSearchQueryChanged,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          alignment: Alignment.topRight,
          duration: const Duration(milliseconds: AppDurations.animNormal),
          child: Padding(
            padding: const EdgeInsets.only(
              top: Spaces.medium,
              left: Spaces.large,
              right: Spaces.large,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: AppDurations.animFast,
                    ),
                    transitionBuilder: (child, animation) {
                      return ClipRect(
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(1, 0),
                            end: Offset(0, 0),
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child:
                        showSearchBar
                            ? searchBar
                            : Row(
                              children: [
                                Spacer(),
                                Tooltip(
                                  message: loc.show_search_bar,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        showSearchBar = !showSearchBar;
                                      });
                                    },
                                    icon: Icon(Icons.search),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
                const SizedBox(width: Spaces.extraSmall),
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
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: Spaces.large + Spaces.extraSmall,
          ),
          child: Text(loc.transactions, style: context.titleLarge),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: Spaces.small,
              left: Spaces.large,
              right: Spaces.large,
            ),
            child: RefreshIndicator(
              onRefresh: () => Future.sync(() => _pagingController.refresh()),
              child: PagedListView<int, TransactionEntry>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<TransactionEntry>(
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

  Future<void> _fetchPage(int pageKey) async {
    talker.info('History - Fetching page: $pageKey');
    try {
      final historyFilterState = ref.read(
        settingsProvider.select((state) => state.historyFilterState),
      );

      final filter = HistoryPageFilter(
        page: BigInt.from(pageKey),
        acceptIncoming: historyFilterState.showIncoming,
        acceptOutgoing: historyFilterState.showOutgoing,
        acceptCoinbase: historyFilterState.showCoinbase,
        acceptBurn: historyFilterState.showBurn,
        limit: BigInt.from(_pageSize),
        assetHash: historyFilterState.asset,
        address: searchQuery.isNotEmpty ? searchQuery : null,
      );

      final newItems = await ref.read(historyProvider(filter).future);

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        talker.info('History - Last page');
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      talker.error('Error fetching page: $error');
      _pagingController.error = error;
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
        _pagingController.refresh();
      }
    });
  }

  void _onSearchQueryClear() {
    _searchFormKey.currentState?.fields['searchQuery']?.reset();
    _searchFocusNode.unfocus();
    if (searchQuery.isNotEmpty) {
      setState(() {
        searchQuery = '';
      });
      _pagingController.refresh();
    }
    setState(() {
      showSearchBar = false;
    });
  }

  void _onSearchQueryChanged(String? value) {
    final network = ref.read(settingsProvider.select((state) => state.network));
    if (value != null && isAddressValid(strAddress: value, network: network)) {
      setState(() {
        searchQuery = value;
      });
      _pagingController.refresh();
    }
  }
}
