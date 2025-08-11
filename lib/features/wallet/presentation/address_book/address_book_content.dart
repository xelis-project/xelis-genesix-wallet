import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/edit_contact_sheet.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/confirm_dialog.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';

class AddressBookContent extends ConsumerStatefulWidget {
  const AddressBookContent({super.key});

  @override
  ConsumerState createState() => _AddressBookContentState();
}

class _AddressBookContentState extends ConsumerState<AddressBookContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final addressBook = ref.watch(addressBookProvider);
    return Column(
      spacing: Spaces.medium,
      children: [
        Padding(
          padding: const EdgeInsets.all(Spaces.small),
          child: FTextField(
            hint: 'search contact...',
            controller: _searchController,
            keyboardType: TextInputType.text,
            maxLines: 1,
            clearable: (value) => value.text.isNotEmpty,
            onChange: (value) =>
                ref.read(searchQueryProvider.notifier).change(value),
          ),
        ),
        switch (addressBook) {
          AsyncData(:final value) =>
            value.isEmpty
                ? Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _searchController.text.isNotEmpty
                              ? loc.no_contact_found
                              : 'Your address book is empty, add a contact!',
                          style: context.theme.typography.base.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  )
                : FItemGroup.builder(
                    count: value.length,
                    itemBuilder: (BuildContext context, int index) {
                      final contact = value.values.elementAt(index);
                      return FItem(
                        prefix: HashiconWidget(
                          hash: contact.address,
                          size: const Size(35, 35),
                        ),
                        title: Text(contact.name),
                        subtitle: Text(
                          truncateText(contact.address, maxLength: 20),
                        ),
                        suffix: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FTooltip(
                              tipBuilder: (context, controller) {
                                return Text('Transfer to ${contact.name}');
                              },
                              child: FButton.icon(
                                onPress: () {
                                  // TODO: Implement transfer action
                                },
                                child: Icon(
                                  FIcons.send,
                                  color: context.theme.colors.primary,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: Spaces.small),
                            FTooltip(
                              tipBuilder: (context, controller) {
                                return Text(loc.edit_contact);
                              },
                              child: FButton.icon(
                                onPress: () => _onEdit(contact),
                                child: const Icon(FIcons.pencil, size: 18),
                              ),
                            ),
                            const SizedBox(width: Spaces.small),
                            FTooltip(
                              tipBuilder: (context, controller) {
                                return Text(loc.remove_contact_button_tooltip);
                              },
                              child: FButton.icon(
                                onPress: () =>
                                    _onDelete(contact.address, contact.name),
                                child: Icon(
                                  FIcons.trash,
                                  color: context.theme.colors.destructive,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          AsyncError() => Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text(loc.oups)],
            ),
          ),
          _ => SizedBox.shrink(),
        },
      ],
    );
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
          description: 'You are about to remove $name from your address book.',
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
