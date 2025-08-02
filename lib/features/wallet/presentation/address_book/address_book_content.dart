import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/search_query_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';

class AddressBookContent extends ConsumerStatefulWidget {
  const AddressBookContent({super.key});

  @override
  ConsumerState createState() => _AddressBookContentState();
}

class _AddressBookContentState extends ConsumerState<AddressBookContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final addressBook = ref.watch(addressBookProvider);
    return Column(
      spacing: Spaces.medium,
      children: [
        Padding(
          padding: const EdgeInsets.all(Spaces.small),
          child: FTextField(
            hint: 'search contact...',
            controller: _searchController,
            keyboardType: TextInputType.text,
            maxLines: 1,
            clearable: (value) => value.text.isNotEmpty,
            onChange: (value) =>
                ref.read(searchQueryProvider.notifier).change(value),
          ),
        ),
        switch (addressBook) {
          AsyncData(:final value) =>
            value.isEmpty
                ? Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(loc.no_contact_found)],
                    ),
                  )
                : FItemGroup.builder(
                    count: value.length,
                    itemBuilder: (BuildContext context, int index) {
                      final contact = value.values.elementAt(index);
                      return FItem(
                        prefix: HashiconWidget(
                          hash: contact.address,
                          size: const Size(35, 35),
                        ),
                        title: Text(contact.name),
                        subtitle: Text(contact.address),
                        suffix: Icon(FIcons.chevronRight),
                        onPress: () {},
                      );
                    },
                  ),
          AsyncError() => Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text(loc.oups)],
            ),
          ),
          _ => SizedBox.shrink(),
        },
      ],
    );
  }
}
