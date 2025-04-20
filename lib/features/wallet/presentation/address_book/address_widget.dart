import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_dialog.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class AddressWidget extends ConsumerStatefulWidget {
  const AddressWidget(this.address, {super.key});

  final String address;

  @override
  ConsumerState createState() => _AddressWidgetState();
}

class _AddressWidgetState extends ConsumerState<AddressWidget> {
  @override
  Widget build(BuildContext context) {
    final future = ref.watch(addressBookProvider.future);
    final loc = ref.watch(appLocalizationsProvider);

    return Row(
      children: [
        HashiconWidget(hash: widget.address, size: const Size(35, 35)),
        const SizedBox(width: Spaces.small),
        Expanded(
          child: FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              final isRegistered =
                  snapshot.data?.containsKey(widget.address) ?? false;

              final value =
                  isRegistered
                      ? snapshot.data![widget.address]!.name
                      : widget.address;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child:
                        isRegistered
                            ? Tooltip(
                              message: widget.address,
                              textStyle: context.bodySmall,
                              child: SelectableText(
                                value,
                                style: context.bodyMedium,
                              ),
                            )
                            : SelectableText(value, style: context.bodySmall),
                  ),
                  const SizedBox(width: Spaces.small),
                  if (!isRegistered)
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: 'add to address book',
                      onPressed: _onAddAddress,
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _onAddAddress() {
    showDialog<void>(
      context: context,
      builder: (context) => AddContactDialog(address: widget.address),
    );
  }
}
