import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_sheet.dart';
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
        HashiconWidget(hash: widget.address, size: const Size(25, 25)),
        const SizedBox(width: Spaces.small),
        Expanded(
          child: FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              final isRegistered =
                  snapshot.data?.containsKey(widget.address) ?? false;

              final value = isRegistered
                  ? snapshot.data![widget.address]!.name
                  : widget.address;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: isRegistered
                        ? FTooltip(
                            tipBuilder: (context, controller) =>
                                Text(widget.address),
                            child: SelectableText(value),
                          )
                        : SelectableText(value),
                  ),
                  const SizedBox(width: Spaces.small),
                  if (!isRegistered)
                    FButton.icon(
                      onPress: _onAddAddress,
                      child: const Icon(FIcons.plus, size: 18),
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
    showFSheet<void>(
      context: context,
      side: FLayout.btt,
      useRootNavigator: true,
      mainAxisMaxRatio: context.getFSheetRatio,
      builder: (context) => AddContactSheet(address: widget.address),
    );
  }
}
