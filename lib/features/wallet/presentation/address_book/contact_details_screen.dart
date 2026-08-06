import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/contact_history_providers.dart';
import 'package:genesix/features/wallet/presentation/address_book/edit_contact_sheet.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/features/wallet/presentation/history/extra_data_sheet.dart';
import 'package:genesix/features/wallet/presentation/history/transaction_grouped_widget.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class ContactDetailsScreen extends ConsumerStatefulWidget {
  const ContactDetailsScreen({super.key, required this.contactId});

  final String contactId;

  @override
  ConsumerState<ContactDetailsScreen> createState() =>
      _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends ConsumerState<ContactDetailsScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final contactAsync = ref.watch(addressBookProvider);

    return FScaffold(
      header: Padding(
        padding: const EdgeInsets.only(top: Spaces.medium),
        child: FHeader.nested(
          title: Text(loc.contact_details),
          prefixes: [
            Padding(
              padding: const EdgeInsets.all(Spaces.small),
              child: FHeaderAction.back(onPress: () => context.pop()),
            ),
          ],
        ),
      ),
      child: contactAsync.when(
        data: (contacts) {
          final contact = contacts[widget.contactId];
          if (contact == null) {
            return _ContactNotFound(localizations: loc);
          }

          return BodyLayoutBuilder(
            child: FadedScroll(
              controller: _scrollController,
              fadeFraction: 0.08,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(Spaces.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: Spaces.medium,
                        children: [
                          _ContactProfileCard(
                            contact: contact,
                            localizations: loc,
                            onSend: () => context.push(
                              AuthAppScreen.transfer.toPath,
                              extra: contact.id,
                            ),
                            onEdit: () => _showEditContactSheet(contact),
                            onViewAttachedData:
                                contact.destination.hasIntegratedData
                                ? () => _showIntegratedData(contact)
                                : null,
                          ),
                          _ContactNotesCard(
                            contact: contact,
                            localizations: loc,
                          ),
                          _TransactionsSectionHeader(title: loc.transactions),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Spaces.medium,
                      Spaces.small,
                      Spaces.medium,
                      Spaces.medium,
                    ),
                    sliver: _ContactHistorySliver(
                      contactAddress: contact.destination.address,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: FCircularProgress()),
        error: (error, stack) => Center(child: Text(loc.oups)),
      ),
    );
  }

  void _showEditContactSheet(XelisAddressBookEntry contact) {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.responsiveSheetMaxRatio,
      builder: (context) => EditContactSheet(contact),
    );
  }

  void _showIntegratedData(XelisAddressBookEntry contact) {
    try {
      final descriptor = XelisWalletFlutter.parseAddress(
        address: contact.destination.address,
      );
      final integratedData = descriptor.integratedData;
      if (integratedData == null ||
          descriptor.encodedAddress != contact.destination.address ||
          descriptor.baseAddress != contact.destination.baseAddress) {
        throw StateError('The saved integrated destination is not canonical.');
      }

      showFSheet<void>(
        context: context,
        side: FLayout.btt,
        useRootNavigator: true,
        mainAxisMaxRatio: context.responsiveSheetMaxRatio,
        builder: (context) =>
            ExtraDataSheet.typed(data: integratedData, visibleInAddress: true),
      );
    } catch (error, stackTrace) {
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.address_book.integrated_data.reveal',
        applicationCode: 'wallet_address_book_integrated_data_invariant_failed',
      );
      ref.read(toastProvider.notifier).showFailure(failure: failure);
    }
  }
}

class _ContactNotFound extends StatelessWidget {
  const _ContactNotFound({required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Spaces.small,
          children: [
            Icon(
              FLucideIcons.circleAlert,
              size: 28,
              color: context.theme.colors.mutedForeground,
            ),
            Text(
              localizations.contact_not_found,
              textAlign: TextAlign.center,
              style: context.theme.typography.display.lg,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactProfileCard extends ConsumerWidget {
  const _ContactProfileCard({
    required this.contact,
    required this.localizations,
    required this.onSend,
    required this.onEdit,
    required this.onViewAttachedData,
  });

  final XelisAddressBookEntry contact;
  final AppLocalizations localizations;
  final VoidCallback onSend;
  final VoidCallback onEdit;
  final VoidCallback? onViewAttachedData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;
            final hashiconSize = compact ? 56.0 : 64.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Spaces.medium,
              children: [
                Row(
                  children: [
                    HashiconWidget(
                      hash: contact.destination.address,
                      size: Size.square(hashiconSize),
                    ),
                    const SizedBox(width: Spaces.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spaces.extraSmall,
                        children: [
                          Text(
                            contact.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (compact
                                        ? context.theme.typography.display.lg
                                        : context.theme.typography.display.xl)
                                    .copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            localizations.address,
                            style: context.theme.typography.body.xs.copyWith(
                              color: context.theme.colors.mutedForeground,
                            ),
                          ),
                          if (contact.destination.hasIntegratedData)
                            FBadge(
                              variant: .secondary,
                              child: Text(
                                localizations.integrated_address_detected,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                FTooltip(
                  tipBuilder: (_, _) => Text(contact.destination.address),
                  child: FButton(
                    variant: .outline,
                    semanticsLabel: localizations.copy,
                    onPress: () => _copyAddress(ref),
                    suffix: const Icon(FLucideIcons.copy, size: 16),
                    builder: (_, _, textStyle, _, _, _) => Expanded(
                      child: Text(
                        contact.destination.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: textStyle,
                      ),
                    ),
                  ),
                ),
                if (onViewAttachedData case final onViewAttachedData?)
                  FButton(
                    variant: .outline,
                    onPress: onViewAttachedData,
                    prefix: const Icon(FLucideIcons.eye, size: 18),
                    child: Text(localizations.view_attached_data),
                  ),
                _ContactActions(
                  localizations: localizations,
                  compact: compact,
                  onSend: onSend,
                  onEdit: onEdit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyAddress(WidgetRef ref) async {
    await Clipboard.setData(ClipboardData(text: contact.destination.address));
    ref
        .read(toastProvider.notifier)
        .showInformation(title: localizations.copied_to_clipboard);
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({
    required this.localizations,
    required this.compact,
    required this.onSend,
    required this.onEdit,
  });

  final AppLocalizations localizations;
  final bool compact;
  final VoidCallback onSend;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sendButton = FButton(
      onPress: onSend,
      prefix: const Icon(FLucideIcons.send, size: 18),
      child: Text(localizations.send),
    );
    final editButton = FButton(
      variant: .outline,
      onPress: onEdit,
      prefix: const Icon(FLucideIcons.pencil, size: 18),
      child: Text(localizations.edit_button),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spaces.small,
        children: [sendButton, editButton],
      );
    }

    return Row(
      spacing: Spaces.small,
      children: [
        Expanded(child: sendButton),
        Expanded(child: editButton),
      ],
    );
  }
}

class _ContactNotesCard extends StatelessWidget {
  const _ContactNotesCard({required this.contact, required this.localizations});

  final XelisAddressBookEntry contact;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final hasNotes = contact.note?.isNotEmpty ?? false;

    return AppCard(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Spaces.small,
          children: [
            Text(
              localizations.notes,
              style: context.theme.typography.display.lg,
            ),
            Text(
              hasNotes ? contact.note! : localizations.no_notes,
              softWrap: true,
              style: context.theme.typography.body.sm.copyWith(
                color: hasNotes ? null : context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionsSectionHeader extends StatelessWidget {
  const _TransactionsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: context.theme.typography.display.lg),
        FDivider(),
      ],
    );
  }
}

class _ContactHistorySliver extends ConsumerStatefulWidget {
  const _ContactHistorySliver({required this.contactAddress});

  final String contactAddress;

  @override
  ConsumerState<_ContactHistorySliver> createState() =>
      _ContactHistorySliverState();
}

class _ContactHistorySliverState extends ConsumerState<_ContactHistorySliver> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final pagingState = ref.watch(
      contactHistoryPagingStateProvider(widget.contactAddress),
    );
    final addressBook = ref.watch(addressBookByAddressProvider);

    switch (addressBook) {
      case AsyncData(:final value):
        return PagedSliverList<
          int,
          MapEntry<DateTime, List<XelisWalletTransactionEntry>>
        >(
          state: pagingState,
          fetchNextPage: _fetchPage,
          shrinkWrapFirstPageIndicators: true,
          builderDelegate:
              PagedChildBuilderDelegate<
                MapEntry<DateTime, List<XelisWalletTransactionEntry>>
              >(
                animateTransitions: true,
                itemBuilder: (context, item, index) =>
                    TransactionGroupedWidget(item, value),
                noItemsFoundIndicatorBuilder: (context) =>
                    _ContactTransactionsEmptyState(
                      message: loc.no_transactions_with_contact,
                    ),
                firstPageProgressIndicatorBuilder: (context) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: Spaces.large),
                  child: Center(child: FCircularProgress()),
                ),
                firstPageErrorIndicatorBuilder: (context) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spaces.large),
                  child: Center(
                    child: Text(
                      loc.oups,
                      style: context.theme.typography.body.md.copyWith(
                        color: context.theme.colors.error,
                      ),
                    ),
                  ),
                ),
              ),
        );
      case AsyncError():
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spaces.large),
            child: Center(
              child: Text(
                loc.oups,
                style: context.theme.typography.body.md.copyWith(
                  color: context.theme.colors.error,
                ),
              ),
            ),
          ),
        );
      default:
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: Spaces.large),
            child: Center(child: FCircularProgress()),
          ),
        );
    }
  }

  void _fetchPage() async {
    final state = ref.read(
      contactHistoryPagingStateProvider(widget.contactAddress),
    );

    if (state.isLoading) return;
    await Future<void>.value();
    ref
        .read(contactHistoryPagingStateProvider(widget.contactAddress).notifier)
        .loading();

    try {
      final newPage = (state.keys?.last ?? 0) + 1;
      logDiagnostic(() => 'operation=contact.history.page.fetch page=$newPage');
      final transactions = await ref.read(
        contactHistoryProvider(widget.contactAddress, newPage).future,
      );

      final grouped = groupTransactionsByDateSorted2Levels(transactions);

      ref
          .read(
            contactHistoryPagingStateProvider(widget.contactAddress).notifier,
          )
          .setNextPage(
            newPage,
            grouped.entries.toList(),
            fetchedTransactionCount: transactions.length,
          );
    } catch (error, stackTrace) {
      logDiagnosticError(
        'contact.history.page.fetch',
        error,
        stackTrace: stackTrace,
      );
      ref
          .read(
            contactHistoryPagingStateProvider(widget.contactAddress).notifier,
          )
          .error(error);
    }
  }
}

class _ContactTransactionsEmptyState extends StatelessWidget {
  const _ContactTransactionsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.large),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.theme.typography.body.sm.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
