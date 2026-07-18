import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_sheet.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_book_empty_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/contact_list_tile.dart';
import 'package:genesix/features/wallet/presentation/address_book/edit_contact_sheet.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/confirm_dialog.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:go_router/go_router.dart';

class AddressBookContent extends ConsumerStatefulWidget {
  const AddressBookContent({super.key});

  @override
  ConsumerState createState() => _AddressBookContentState();
}

class _AddressBookContentState extends ConsumerState<AddressBookContent> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final hasMore = ref.read(addressBookProvider.notifier).hasMore;
    if (!hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      await ref.read(addressBookProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final addressBook = ref.watch(addressBookProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.isNotEmpty;

    ref.listen(searchQueryProvider, (previous, next) {
      if (previous != next) {
        ref.read(addressBookProvider.notifier).reset();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchBar(
          localizations: loc,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).change(value);
          },
        ),
        const SizedBox(height: Spaces.medium),
        Expanded(
          child: switch (addressBook) {
            AsyncData(:final value) =>
              value.isEmpty
                  ? _EmptyStateSwitcher(
                      localizations: loc,
                      isSearching: isSearching,
                      onAddContact: _onAddContact,
                    )
                  : _ContactList(
                      contacts: value,
                      localizations: loc,
                      scrollController: _scrollController,
                      isLoadingMore: _isLoadingMore,
                      onOpen: (contact) => context.push(
                        '/contact_details',
                        extra: contact.address,
                      ),
                      onSend: (contact) => _onSend(contact.address),
                      onEdit: _onEdit,
                      onDelete: (contact) =>
                          _onDelete(contact.address, contact.name),
                    ),
            AsyncError() => _CenteredInfo(message: loc.oups),
            _ => const Center(child: FCircularProgress()),
          },
        ),
      ],
    );
  }

  void _onSend(String address) {
    context.push(AuthAppScreen.transfer.toPath, extra: address);
  }

  void _onEdit(ContactDetails contactDetails) {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.responsiveSheetMaxRatio,
      builder: (context) => EditContactSheet(contactDetails),
    );
  }

  void _onAddContact() {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.responsiveSheetMaxRatio,
      builder: (context) => const AddContactSheet(),
    );
  }

  void _onDelete(String address, String name) {
    final loc = ref.read(appLocalizationsProvider);
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) {
        return ConfirmDialog(
          description: loc.contact_delete_confirm(name),
          style: style,
          animation: animation,
          onConfirm: (bool yes) {
            if (!yes) return;
            try {
              ref.read(addressBookProvider.notifier).remove(address);
              ref
                  .read(toastProvider.notifier)
                  .showEvent(
                    description: '${loc.removed_from_address_book} $name',
                  );
            } catch (e) {
              ref
                  .read(toastProvider.notifier)
                  .showError(description: '${loc.failed_to_remove_contact} $e');
            }
          },
        );
      },
    );
  }
}

/// ————— Widgets —————

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.localizations, required this.onChanged});

  final AppLocalizations localizations;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return FTextField(
      hint: localizations.search,
      prefixBuilder: (context, style, states) => FTextField.prefixIconBuilder(
        context,
        style,
        states,
        const Icon(FLucideIcons.search),
      ),
      control: .managed(
        onChange: (value) {
          onChanged.call(value.text);
        },
      ),
      keyboardType: TextInputType.text,
      maxLines: 1,
      clearable: (v) => v.text.isNotEmpty,
    );
  }
}

class _EmptyStateSwitcher extends StatelessWidget {
  const _EmptyStateSwitcher({
    required this.localizations,
    required this.isSearching,
    required this.onAddContact,
  });

  final AppLocalizations localizations;
  final bool isSearching;
  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: isSearching
            ? AddressBookEmptyState.noSearchResults(
                key: const ValueKey('empty-search'),
                localizations: localizations,
              )
            : AddressBookEmptyState.noContacts(
                key: const ValueKey('empty-all'),
                localizations: localizations,
                onAddContact: onAddContact,
              ),
      ),
    );
  }
}

class _ContactList extends StatelessWidget {
  const _ContactList({
    required this.contacts,
    required this.localizations,
    required this.scrollController,
    required this.isLoadingMore,
    required this.onOpen,
    required this.onSend,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, ContactDetails> contacts;
  final AppLocalizations localizations;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final ValueChanged<ContactDetails> onOpen;
  final ValueChanged<ContactDetails> onSend;
  final ValueChanged<ContactDetails> onEdit;
  final ValueChanged<ContactDetails> onDelete;

  @override
  Widget build(BuildContext context) {
    return FadedScroll(
      controller: scrollController,
      fadeFraction: 0.08,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            FItemGroup.builder(
              count: contacts.length,
              itemBuilder: (BuildContext context, int index) {
                final contact = contacts.values.elementAt(index);
                return ContactListTile(
                  contact: contact,
                  localizations: localizations,
                  onOpen: () => onOpen(contact),
                  onSend: () => onSend(contact),
                  onEdit: () => onEdit(contact),
                  onDelete: () => onDelete(contact),
                );
              },
            ),
            if (isLoadingMore)
              Padding(
                padding: const EdgeInsets.all(Spaces.medium),
                child: Center(child: FCircularProgress()),
              ),
          ],
        ),
      ),
    );
  }
}

class _CenteredInfo extends StatelessWidget {
  const _CenteredInfo({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.theme.typography.body.md.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
