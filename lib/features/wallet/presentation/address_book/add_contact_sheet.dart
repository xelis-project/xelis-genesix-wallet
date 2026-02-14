import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/sheet_content.dart';
import 'package:genesix/src/generated/rust_bridge/api/utils.dart';
import 'package:go_router/go_router.dart';

class AddContactSheet extends ConsumerStatefulWidget {
  const AddContactSheet({super.key, this.address});

  final String? address;

  @override
  ConsumerState createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<AddContactSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _addressController.text = widget.address!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return SheetContent(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            FTextFormField(
              control: .managed(controller: _nameController),
              label: Text(loc.contact_name),
              hint: loc.contact_name_hint,
              keyboardType: TextInputType.text,
              maxLines: 1,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              control: .managed(controller: _addressController),
              label: Text(loc.address),
              hint: 'xel:0x1234567890abcdef1234567890abcdef12345678',
              enabled: widget.address == null,
              keyboardType: TextInputType.text,
              maxLines: 1,
              autocorrect: false,
              validator: _addressValidator,
            ),
            const SizedBox(height: Spaces.large),
            FButton(
              child: Text(loc.add_contact),
              onPress: () {
                if (_formKey.currentState?.validate() ?? false) {
                  final name = _nameController.text.trim();
                  final address = _addressController.text.trim();
                  try {
                    ref
                        .read(addressBookProvider.notifier)
                        .upsert(address, name, null);

                    ref
                        .read(toastProvider.notifier)
                        .showEvent(
                          description: '${loc.added_to_address_book} $name',
                        );

                    context.pop(); // Close the sheet after adding the contact
                  } catch (e) {
                    ref
                        .read(toastProvider.notifier)
                        .showError(
                          title: loc.failed_to_add_contact,
                          description: e.toString(),
                        );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _addressValidator(String? value) {
    final loc = ref.read(appLocalizationsProvider);

    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return loc.field_required_error;
    }

    final network = ref.read(settingsProvider.select((state) => state.network));

    if (!isAddressValid(strAddress: value.trim(), network: network)) {
      return loc.invalid_address_format_error;
    }

    if (widget.address == null) {
      final addressBook = ref.read(addressBookProvider).value ?? {};
      if (addressBook.containsKey(value.trim())) {
        return loc.contact_already_exists;
      }
    }
    return null;
  }
}
