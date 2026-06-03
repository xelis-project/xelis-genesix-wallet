import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_book_empty_state.dart';
import 'package:genesix/features/wallet/presentation/address_book/contact_list_tile.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';

class SelectAddressDialog extends ConsumerStatefulWidget {
  const SelectAddressDialog(this.animation, {super.key});

  final Animation<double> animation;

  @override
  ConsumerState<SelectAddressDialog> createState() =>
      _SelectAddressDialogState();
}

class _SelectAddressDialogState extends ConsumerState<SelectAddressDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final addressBook = ref.watch(addressBookProvider);

    return FDialog(
      clipBehavior: Clip.antiAlias,
      animation: widget.animation,
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.address_book,
                style: context.theme.typography.xl2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              FButton.icon(
                onPress: () => context.pop(),
                child: const Icon(FLucideIcons.x, size: 20),
              ),
            ],
          ),
          const SizedBox(height: Spaces.large),

          // Search Field
          FTextField(
            prefixBuilder: (context, style, states) =>
                FTextField.prefixIconBuilder(
                  context,
                  style,
                  states,
                  const Icon(FLucideIcons.search),
                ),
            control: .managed(
              onChange: (value) {
                setState(() {
                  _searchQuery = value.text;
                });
              },
            ),
            hint: loc.filter_contacts_label_text,
            keyboardType: TextInputType.text,
            maxLines: 1,
            clearable: (v) => v.text.isNotEmpty,
          ),
          const SizedBox(height: Spaces.large),

          // Contacts List
          Flexible(
            child: addressBook.when(
              data: (book) {
                if (book.isEmpty) {
                  return AddressBookEmptyState.noContacts(
                    localizations: loc,
                    compact: true,
                  );
                }

                final filteredContacts = book.entries.where((entry) {
                  if (_searchQuery.isEmpty) return true;
                  final lowerQuery = _searchQuery.toLowerCase();
                  return entry.value.name.toLowerCase().contains(lowerQuery) ||
                      entry.key.toLowerCase().contains(lowerQuery);
                }).toList();

                if (filteredContacts.isEmpty) {
                  return AddressBookEmptyState.noSearchResults(
                    localizations: loc,
                    compact: true,
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final entry = filteredContacts[index];
                    final address = entry.key;
                    final details = entry.value;
                    return ContactListTile(
                      contact: details,
                      localizations: loc,
                      onOpen: () => context.pop(address),
                    );
                  },
                );
              },
              loading: () => const Center(child: FCircularProgress()),
              error: (error, stack) => _CenteredMessage(
                loc.error_loading_contacts,
                destructive: true,
              ),
            ),
          ),
        ],
      ),
      actions: const [],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage(this.message, {this.destructive = false});

  final String message;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    Color color = colors.foreground;
    if (destructive) {
      color = colors.destructiveForeground;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.theme.typography.md.copyWith(color: color),
        ),
      ),
    );
  }
}
