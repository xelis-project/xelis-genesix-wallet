import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_dialog.dart';
import 'package:genesix/features/wallet/presentation/address_book/edit_contact_dialog.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/confirm_dialog.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class AddressBookScreen extends ConsumerStatefulWidget {
  const AddressBookScreen({super.key});

  @override
  ConsumerState createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  final _formKey = GlobalKey<FormBuilderState>(
    debugLabel: '_addressBookSearchFormKey',
  );
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final future = ref.watch(addressBookProvider.future);
    return CustomScaffold(
      appBar: GenericAppBar(title: 'Address Book'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: Spaces.large,
              right: Spaces.large,
              top: Spaces.small,
            ),
            child: FormBuilder(
              key: _formKey,
              child: FormBuilderTextField(
                name: 'search',
                focusNode: _searchFocusNode,
                style: context.bodyLarge,
                autocorrect: false,
                keyboardType: TextInputType.text,
                decoration: context.textInputDecoration.copyWith(
                  labelText: 'Type a name to filter contacts',
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
                onChanged: (value) {
                  // workaround to reset the error message when the user modifies the field
                  final hasError =
                      _formKey.currentState?.fields['search']?.hasError;
                  if (hasError ?? false) {
                    _formKey.currentState?.fields['search']?.reset();
                  }

                  ref.read(searchQueryProvider.notifier).change(value ?? '');
                },
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: Spaces.large,
                right: Spaces.large,
                bottom: Spaces.large,
                top: Spaces.small,
              ),
              child: Container(
                padding: const EdgeInsets.all(Spaces.small),
                decoration: BoxDecoration(
                  color: context.colors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: double.maxFinite,
                child: FutureBuilder(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!.isEmpty) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'No contacts found',
                              style: context.textTheme.bodyLarge?.copyWith(
                                color: context.moreColors.mutedColor,
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.separated(
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final entry = snapshot.data!.entries.elementAt(index);
                          final address = entry.key;
                          final details = entry.value;
                          return ListTile(
                            leading: HashiconWidget(
                              hash: address,
                              size: const Size(35, 35),
                            ),
                            title: Text(
                              details.name,
                              style: context.titleLarge,
                            ),
                            subtitle: InkWell(
                              onTap:
                                  () =>
                                      copyToClipboard(address, ref, loc.copied),
                              child: Tooltip(
                                message: address,
                                child: Text(
                                  truncateText(address, maxLength: 20),
                                  style: context.bodySmall?.copyWith(
                                    color: context.moreColors.mutedColor,
                                  ),
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  tooltip: 'edit contact',
                                  onPressed: () => _onEditContact(address),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  tooltip: 'remove from address book',
                                  onPressed:
                                      () => _onRemoveAddress(
                                        address,
                                        details.name,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _onAddNewContact,
        child: Icon(Icons.add),
      ),
    );
  }

  void _onEditContact(String address) {
    showDialog<void>(
      context: context,
      builder: (context) => EditContactDialog(address),
    );
  }

  void _onRemoveAddress(String address, String name) {
    showDialog<void>(
      context: context,
      builder:
          (context) => ConfirmDialog(
            title: 'Are you sure you want to delete this contact?',
            onConfirm: (confirmed) {
              if (!confirmed) return;
              try {
                ref.read(addressBookProvider.notifier).remove(address);
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showInfo(
                      '$name removed from address book',
                      durationInSeconds: 2,
                    );
              } catch (e) {
                ref
                    .read(snackBarMessengerProvider.notifier)
                    .showError('Failed to remove contact: $e');
              }
            },
          ),
    );
  }

  void _onAddNewContact() {
    showDialog<void>(
      context: context,
      builder: (context) => AddContactDialog(),
    );
  }

  void _onSearchQueryClear() {
    _formKey.currentState?.fields['search']?.reset();
    _searchFocusNode.unfocus();
    ref.read(searchQueryProvider.notifier).clear();
  }
}
