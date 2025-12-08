import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class SelectAddressDialog extends ConsumerStatefulWidget {
  const SelectAddressDialog({super.key});

  @override
  ConsumerState<SelectAddressDialog> createState() =>
      _SelectAddressDialogState();
}

class _SelectAddressDialogState extends ConsumerState<SelectAddressDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final addressBook = ref.watch(addressBookProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(Spaces.large),
          child: Column(
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
                    onPress: () => Navigator.of(context).pop(),
                    child: const Icon(FIcons.x, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: Spaces.large),

              // Search Field
              FTextField(
                controller: _searchController,
                hint: loc.filter_contacts_label_text,
                keyboardType: TextInputType.text,
                maxLines: 1,
                clearable: (v) => v.text.isNotEmpty,
                onChange: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: Spaces.large),

              // Contacts List
              Expanded(
                child: addressBook.when(
                  data: (book) {
                    if (book.isEmpty) {
                      return Center(
                        child: Text(
                          loc.no_contact_found,
                          style: context.theme.typography.base.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      );
                    }

                    final filteredContacts = book.entries.where((entry) {
                      if (_searchQuery.isEmpty) return true;
                      final lowerQuery = _searchQuery.toLowerCase();
                      return entry.value.name.toLowerCase().contains(
                            lowerQuery,
                          ) ||
                          entry.key.toLowerCase().contains(lowerQuery);
                    }).toList();

                    if (filteredContacts.isEmpty) {
                      return Center(
                        child: Text(
                          loc.no_contact_found,
                          style: context.theme.typography.base.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredContacts.length,
                      separatorBuilder: (context, index) => const FDivider(),
                      itemBuilder: (context, index) {
                        final entry = filteredContacts[index];
                        final address = entry.key;
                        final details = entry.value;
                        return FItem(
                          onPress: () => Navigator.of(context).pop(address),
                          prefix: HashiconWidget(
                            hash: address,
                            size: const Size(40, 40),
                          ),
                          title: Text(details.name),
                          subtitle: Text(truncateText(address)),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      loc.error_loading_contacts,
                      style: context.theme.typography.base.copyWith(
                        color: context.theme.colors.destructiveForeground,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
