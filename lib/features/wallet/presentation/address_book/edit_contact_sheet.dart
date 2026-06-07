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
  late String _name;
  late String _address;
  late String _note;

  @override
  void initState() {
    super.initState();
    _name = widget.contactDetails.name;
    _address = widget.contactDetails.address;
    _note = widget.contactDetails.note ?? '';
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
              control: .managed(
                initial: TextEditingValue(text: _name),
                onChange: (value) => _name = value.text,
              ),
              label: Text(loc.contact_name),
              keyboardType: TextInputType.text,
              maxLines: 1,
              autocorrect: false,
              selectAllOnFocus: true,
              validator: (value) {
                if (value == null || value.isEmpty || value.trim().isEmpty) {
                  return loc.field_required_error;
                }
                return null;
              },
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              control: .managed(initial: TextEditingValue(text: _address)),
              label: Text(loc.address),
              enabled: false,
              maxLines: 1,
            ),
            const SizedBox(height: Spaces.medium),
            FTextFormField(
              control: .managed(
                initial: TextEditingValue(text: _note),
                onChange: (value) => _note = value.text,
              ),
              label: Text(loc.notes),
              hint: loc.enter_notes,
              keyboardType: TextInputType.multiline,
              maxLines: 4,
            ),
            const SizedBox(height: Spaces.large),
            FButton(onPress: _saveContact, child: Text(loc.save)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContact() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final loc = ref.read(appLocalizationsProvider);
    final name = _name.trim();
    final address = _address.trim();
    final note = _note.trim();

    try {
      await ref
          .read(addressBookProvider.notifier)
          .upsert(address, name, note.isEmpty ? null : note);

      ref
          .read(toastProvider.notifier)
          .showInformation(title: loc.contact_updated);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ref
          .read(toastProvider.notifier)
          .showError(
            title: loc.failed_to_update_contact,
            description: e.toString(),
          );
    }
  }
}
