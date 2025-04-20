import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:go_router/go_router.dart';

class SelectAddressDialog extends ConsumerStatefulWidget {
  const SelectAddressDialog({super.key});

  @override
  ConsumerState<SelectAddressDialog> createState() =>
      _SelectAddressDialogState();
}

class _SelectAddressDialogState extends ConsumerState<SelectAddressDialog> {
  final _formKey = GlobalKey<FormBuilderState>(
    debugLabel: '_selectSearchFormKey',
  );
  String? _searchText;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final future = ref.watch(
      addressBookProvider(startWith: _searchText).future,
    );
    return GenericDialog(
      scrollable: false,
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  'Address Book',
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
        width: double.maxFinite,
        padding: const EdgeInsets.all(Spaces.small),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Spaces.small),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            FormBuilder(
              child: FormBuilderTextField(
                name: 'search',
                style: context.bodyLarge,
                autocorrect: false,
                keyboardType: TextInputType.text,
                decoration: context.textInputDecoration.copyWith(
                  labelText: 'Type a name to filter contacts',
                ),
                onChanged: (value) {
                  // workaround to reset the error message when the user modifies the field
                  final hasError =
                      _formKey.currentState?.fields['address']?.hasError;
                  if (hasError ?? false) {
                    _formKey.currentState?.fields['address']?.reset();
                  }

                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),
            const SizedBox(height: Spaces.medium),
            FutureBuilder(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.isEmpty) {
                    return Expanded(
                      child: Column(
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
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
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
                        title: Text(details.name, style: context.titleLarge),
                        subtitle: Tooltip(
                          message: address,
                          child: Text(
                            truncateText(address, maxLength: 20),
                            style: context.bodySmall?.copyWith(
                              color: context.moreColors.mutedColor,
                            ),
                          ),
                        ),
                        onTap: () => context.pop(entry.key),
                      );
                    },
                  );
                } else {
                  if (snapshot.hasError) {
                    ref
                        .read(snackBarMessengerProvider.notifier)
                        .showError('Error loading contacts: ${snapshot.error}');
                  }
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
