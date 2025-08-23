import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_sheet.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class AddressWidget extends ConsumerStatefulWidget {
  const AddressWidget(this.address, {super.key, this.displayHashicon = true});

  final String address;

  final bool displayHashicon;

  @override
  ConsumerState createState() => _AddressWidgetState();
}

class _AddressWidgetState extends ConsumerState<AddressWidget> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final future = ref.watch(addressBookProvider.future);

    return Row(
      children: [
        if (widget.displayHashicon)
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
                            child: SelectableText(
                              value,
                              style: context.theme.typography.base,
                            ),
                          )
                        : SelectableText(
                            value,
                            style: context.theme.typography.base,
                          ),
                  ),
                  const SizedBox(width: Spaces.small),
                  if (!isRegistered)
                    FTooltip(
                      tipBuilder: (context, controller) {
                        return Text(
                          loc.add_to_address_book_tooltip,
                          style: context.theme.typography.base,
                        );
                      },
                      child: FButton.icon(
                        onPress: _onAddAddress,
                        child: const Icon(FIcons.plus, size: 18),
                      ),
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
