import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:go_router/go_router.dart';

class SelectAddressDialog extends ConsumerStatefulWidget {
  const SelectAddressDialog(this.style, this.animation, {super.key});

  final FDialogStyle style;
  final Animation<double> animation;

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

    return FDialog(
      style: widget.style,
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
          Flexible(
            child: addressBook.when(
              data: (book) {
                if (book.isEmpty) {
                  return _CenteredMessage(loc.no_contact_found, muted: true);
                }

                final filteredContacts = book.entries.where((entry) {
                  if (_searchQuery.isEmpty) return true;
                  final lowerQuery = _searchQuery.toLowerCase();
                  return entry.value.name.toLowerCase().contains(lowerQuery) ||
                      entry.key.toLowerCase().contains(lowerQuery);
                }).toList();

                if (filteredContacts.isEmpty) {
                  return _CenteredMessage(loc.no_contact_found, muted: true);
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
                      onPress: () => context.pop(address),
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
  const _CenteredMessage(
    this.message, {
    this.destructive = false,
    this.muted = false,
  });

  final String message;
  final bool destructive;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    Color color = colors.foreground;
    if (destructive) {
      color = colors.destructiveForeground;
    } else if (muted) {
      color = colors.mutedForeground;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.theme.typography.base.copyWith(color: color),
        ),
      ),
    );
  }
}
