import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/history_providers.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/filter_dialog.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/transaction_entry_widget.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
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
  final GlobalKey<FormBuilderState> _searchFormKey =
      GlobalKey<FormBuilderState>();
  final _searchFocusNode = FocusNode();

  bool showSearchBar = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(historySearchQueryProvider);
    final loc = ref.watch(appLocalizationsProvider);
    final pagingState = ref.watch(historyPagingStateProvider);
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

  void _onSearchQueryClear() {
    _searchFormKey.currentState?.fields['searchQuery']?.reset();
    _searchFocusNode.unfocus();
    ref.read(historySearchQueryProvider.notifier).clear();
    setState(() {
      showSearchBar = false;
    });
  }

  void _onSearchQueryChanged(String? value) {
    final network = ref.read(settingsProvider.select((state) => state.network));
    if (value != null && isAddressValid(strAddress: value, network: network)) {
      ref.read(historySearchQueryProvider.notifier).change(value);
    }
  }
}
