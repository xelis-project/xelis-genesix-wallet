import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/contact_history_providers.dart';
import 'package:genesix/features/wallet/presentation/address_book/edit_contact_sheet.dart';
import 'package:genesix/features/wallet/presentation/components/transaction_view_utils.dart';
import 'package:genesix/features/wallet/presentation/history/transaction_grouped_widget.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class ContactDetailsScreen extends ConsumerStatefulWidget {
  const ContactDetailsScreen({super.key, required this.contactAddress});

  final String contactAddress;

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
          final contact = contacts[widget.contactAddress];
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
                              extra: contact.address,
                            ),
                            onEdit: () => _showEditContactSheet(contact),
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
                      contactAddress: widget.contactAddress,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: FCircularProgress()),
        error: (error, stack) => Center(child: Text('${loc.error}: $error')),
      ),
    );
  }

  void _showEditContactSheet(ContactDetails contact) {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.getFSheetRatio,
      builder: (context) => EditContactSheet(contact),
    );
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
  });

  final ContactDetails contact;
  final AppLocalizations localizations;
  final VoidCallback onSend;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FCard(
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
                      hash: contact.address,
                      size: Size.square(hashiconSize),
                    ),
                    const SizedBox(width: Spaces.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: Spaces.extraSmall,
                        children: [
                          Text(
                            contact.name,
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
                        ],
                      ),
                    ),
                  ],
                ),
                FTooltip(
                  tipBuilder: (_, _) => Text(contact.address),
                  child: FButton(
                    variant: .outline,
                    semanticsLabel: localizations.copy,
                    onPress: () => _copyAddress(ref),
                    suffix: const Icon(FLucideIcons.copy, size: 16),
                    builder: (_, _, textStyle, _, _, _) => Expanded(
                      child: Text(
                        contact.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: textStyle,
                      ),
                    ),
                  ),
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

  void _copyAddress(WidgetRef ref) {
    Clipboard.setData(ClipboardData(text: contact.address));
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

  final ContactDetails contact;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final hasNotes = contact.note?.isNotEmpty ?? false;

    return FCard(
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
    final addressBook = ref.watch(addressBookProvider);

    switch (addressBook) {
      case AsyncData(:final value):
        return PagedSliverList<int, MapEntry<DateTime, List<TransactionEntry>>>(
          state: pagingState,
          fetchNextPage: _fetchPage,
          shrinkWrapFirstPageIndicators: true,
          builderDelegate:
              PagedChildBuilderDelegate<
                MapEntry<DateTime, List<TransactionEntry>>
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
      talker.info('Fetching contact history page: $newPage');
      final transactions = await ref.read(
        contactHistoryProvider(widget.contactAddress, newPage).future,
      );

      final grouped = groupTransactionsByDateSorted2Levels(transactions);

      ref
          .read(
            contactHistoryPagingStateProvider(widget.contactAddress).notifier,
          )
          .setNextPage(newPage, grouped.entries.toList());
    } catch (error) {
      talker.error('Error fetching contact history page: $error');
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
