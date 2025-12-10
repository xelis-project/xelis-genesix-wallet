import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/edit_contact_sheet.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/confirm_dialog.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';

class AddressBookContent extends ConsumerStatefulWidget {
  const AddressBookContent({super.key});

  @override
  ConsumerState createState() => _AddressBookContentState();
}

class _AddressBookContentState extends ConsumerState<AddressBookContent> {
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.dispose();
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

    return FadedScroll(
      controller: _scrollController,
      fadeFraction: 0.08,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: switch (addressBook) {
          AsyncData(:final value) => Builder(
            builder: (context) {
              return Column(
                spacing: Spaces.medium,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SearchBar(
                    localizations: loc,
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).change(value);
                    },
                    onClear: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                  ),
                  value.isEmpty
                      ? _CenteredInfo(
                          message: isSearching
                              ? loc.no_contact_found
                              : loc.address_book_empty,
                        )
                      : Column(
                          children: [
                            FItemGroup.builder(
                              count: value.length,
                              itemBuilder: (BuildContext context, int index) {
                                final contact = value.values.elementAt(index);
                                return FItem(
                                  onPress: () => ContactDetailsRoute(
                                    $extra: contact.address,
                                  ).push<void>(context),
                                  prefix: HashiconWidget(
                                    hash: contact.address,
                                    size: const Size(35, 35),
                                  ),
                                  title: Text(contact.name),
                                  subtitle: Text(
                                    truncateText(
                                      contact.address,
                                      maxLength: 20,
                                    ),
                                  ),
                                  suffix: _ContactActions(
                                    localizations: loc,
                                    name: contact.name,
                                    onSend: () => _onSend(contact.address),
                                    onEdit: () => _onEdit(contact),
                                    onDelete: () => _onDelete(
                                      contact.address,
                                      contact.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (_isLoadingMore)
                              Padding(
                                padding: const EdgeInsets.all(Spaces.medium),
                                child: Center(child: FProgress.circularIcon()),
                              ),
                          ],
                        ),
                ],
              );
            },
          ),
          AsyncError() => Column(
            spacing: Spaces.medium,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SearchBar(
                localizations: loc,
                controller: _searchController,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).change(value);
                },
                onClear: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).clear();
                },
              ),
              _CenteredInfo(message: loc.oups),
            ],
          ),
          _ => Column(
            spacing: Spaces.medium,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SearchBar(
                localizations: loc,
                controller: _searchController,
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).change(value);
                },
                onClear: () {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).clear();
                },
              ),
            ],
          ),
        },
      ),
    );
  }

  void _onSend(String address) {
    TransferRoute($extra: address).go(context);
  }

  void _onEdit(ContactDetails contactDetails) {
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.getFSheetRatio,
      builder: (context) => EditContactSheet(contactDetails),
    );
  }

  void _onDelete(String address, String name) {
    final loc = ref.read(appLocalizationsProvider);
    showFDialog<void>(
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
  const _SearchBar({
    required this.localizations,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final AppLocalizations localizations;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return FTextField(
      hint: localizations.search,
      controller: controller,
      keyboardType: TextInputType.text,
      maxLines: 1,
      clearable: (v) => v.text.isNotEmpty,
      onChange: onChanged,
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
          style: context.theme.typography.base.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({
    required this.localizations,
    required this.name,
    // required this.address,
    required this.onSend,
    required this.onEdit,
    required this.onDelete,
  });

  final AppLocalizations localizations;
  final String name;

  // final String address;
  final VoidCallback onSend;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: Spaces.small,
      children: [
        FTooltip(
          tipBuilder: (_, _) => Text(localizations.transfer_to_contact(name)),
          child: FButton.icon(
            onPress: onSend,
            child: Icon(
              FIcons.send,
              color: context.theme.colors.primary,
              size: 18,
            ),
          ),
        ),
        FTooltip(
          tipBuilder: (_, _) => Text(localizations.edit_contact),
          child: FButton.icon(
            onPress: onEdit,
            child: const Icon(FIcons.pencil, size: 18),
          ),
        ),
        FTooltip(
          tipBuilder: (_, _) =>
              Text(localizations.remove_contact_button_tooltip),
          child: FButton.icon(
            onPress: onDelete,
            child: Icon(
              FIcons.trash,
              color: context.theme.colors.destructive,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
