import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/add_contact_sheet.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class AddressWidget extends ConsumerStatefulWidget {
  const AddressWidget(
    this.address, {
    super.key,
    this.displayHashicon = true,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.compact = false,
    this.compactAddressMaxLength = 18,
  });

  final String address;

  final bool displayHashicon;
  final MainAxisAlignment mainAxisAlignment;
  final bool compact;
  final int compactAddressMaxLength;

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
        if (widget.displayHashicon) ...[
          HashiconWidget(hash: widget.address, size: const Size(25, 25)),
          const SizedBox(width: Spaces.small),
        ],
        Expanded(
          child: FutureBuilder(
            future: future,
            builder: (context, snapshot) {
              final isRegistered =
                  snapshot.data?.containsKey(widget.address) ?? false;

              final value = isRegistered
                  ? snapshot.data![widget.address]!.name
                  : widget.address;
              final displayValue = widget.compact && !isRegistered
                  ? truncateText(
                      widget.address,
                      maxLength: widget.compactAddressMaxLength,
                    )
                  : value;
              final valueText = SelectableText(
                displayValue,
                maxLines: widget.compact ? 1 : null,
                style: context.theme.typography.body.md,
              );

              return Row(
                mainAxisAlignment: widget.mainAxisAlignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: isRegistered
                        ? FTooltip(
                            tipBuilder: (context, controller) =>
                                Text(widget.address),
                            child: valueText,
                          )
                        : FTooltip(
                            tipBuilder: (context, controller) =>
                                Text(widget.address),
                            child: valueText,
                          ),
                  ),
                  if (!isRegistered) ...[
                    const SizedBox(width: Spaces.small),
                    FTooltip(
                      tipBuilder: (context, controller) {
                        return Text(
                          loc.add_to_address_book_tooltip,
                          style: context.theme.typography.body.md,
                        );
                      },
                      child: widget.compact
                          ? FButton.icon(
                              variant: .ghost,
                              onPress: _onAddAddress,
                              child: const Icon(FLucideIcons.plus, size: 16),
                            )
                          : FButton.icon(
                              onPress: _onAddAddress,
                              child: const Icon(FLucideIcons.plus, size: 18),
                            ),
                    ),
                  ],
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
