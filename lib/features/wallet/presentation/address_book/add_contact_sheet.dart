import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/sheet_content.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class AddContactSheet extends ConsumerStatefulWidget {
  const AddContactSheet({super.key, this.address});

  final String? address;

  @override
  ConsumerState createState() => _AddContactSheetState();
}

class _AddContactSheetState extends ConsumerState<AddContactSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _name;
  late String _address;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = '';
    _address = widget.address ?? '';
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
              control: .managed(onChange: (value) => _name = value.text),
              label: Text(loc.contact_name),
              hint: loc.contact_name_hint,
              keyboardType: TextInputType.text,
              autofocus: true,
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
              control: .managed(
                initial: TextEditingValue(text: _address),
                onChange: (value) => _address = value.text,
              ),
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
              onPress: _isSaving ? null : _saveContact,
              child: Text(loc.add_contact),
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

    if (!XelisWalletFlutter.isAddressValid(
      address: value.trim(),
      network: network,
    )) {
      return loc.invalid_address_format_error;
    }

    return null;
  }

  Future<void> _saveContact() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;

    final loc = ref.read(appLocalizationsProvider);
    final name = _name.trim();
    final address = _address.trim();

    setState(() => _isSaving = true);
    try {
      final addressBook = ref.read(addressBookProvider.notifier);
      if (await addressBook.containsExactAddress(address)) {
        if (!mounted) return;
        ref
            .read(toastProvider.notifier)
            .showError(description: loc.contact_already_exists);
        return;
      }

      if (!mounted) return;
      await addressBook.upsert(address: address, displayName: name);

      if (!mounted) return;
      ref
          .read(toastProvider.notifier)
          .showEvent(description: '${loc.added_to_address_book} $name');

      context.pop();
    } catch (error, stackTrace) {
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.address_book.create',
        applicationCode: 'wallet_address_book_create_failed',
      );
      if (!mounted) return;
      ref
          .read(toastProvider.notifier)
          .showFailure(title: loc.failed_to_add_contact, failure: failure);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
