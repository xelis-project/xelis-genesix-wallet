import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/sheet_content.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:go_router/go_router.dart';

class EditContactSheet extends ConsumerStatefulWidget {
  const EditContactSheet(this.contactDetails, {super.key});

  // final String address;
  final ContactDetails contactDetails;

  @override
  ConsumerState createState() => _EditContactSheetState();
}

class _EditContactSheetState extends ConsumerState<EditContactSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.contactDetails.name;
    _addressController.text = widget.contactDetails.address;
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
              controller: _nameController,
              label: Text('Contact Name'),
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
              controller: _addressController,
              label: Text('Address'),
              // hint: 'xel:0x1234567890abcdef1234567890abcdef12345678',
              enabled: false,
              // keyboardType: TextInputType.text,
              maxLines: 1,
              // autocorrect: false,
              // validator: _addressValidator,
            ),
            const SizedBox(height: Spaces.large),
            FButton(
              child: Text(loc.save),
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
                        .showInformation(title: loc.contact_updated);

                    context.pop(); // Close the sheet after adding the contact
                  } catch (e) {
                    ref
                        .read(toastProvider.notifier)
                        .showError(
                          title: loc.failed_to_update_contact,
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
}
