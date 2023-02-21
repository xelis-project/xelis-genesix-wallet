import 'package:flutter/material.dart';
import 'package:xelis_wallet_app/shared/theme/extensions.dart';

const List<String> walletNamesExample = <String>[
  'wallet1',
  'wallet2',
  'wallet3',
  'wallet4',
];

class DropdownWalletNameMenu extends StatefulWidget {
  const DropdownWalletNameMenu({super.key});

  @override
  State<DropdownWalletNameMenu> createState() => _DropdownWalletNameMenuState();
}

class _DropdownWalletNameMenuState extends State<DropdownWalletNameMenu> {
  // final TextEditingController walletNameController = TextEditingController();
  String selectedValue = walletNamesExample.first;

  @override
  Widget build(BuildContext context) {
    /*final walletNames = <DropdownMenuEntry<String>>[];
    for (final name in walletNamesExample) {
      walletNames.add(
        DropdownMenuEntry<String>(
          value: name,
          label: name,
        ),
      );
    }

    return DropdownMenu(
      // width: 300,
      dropdownMenuEntries: walletNames,
      label: const Text('Wallet name'),
      // controller: walletNameController,
      initialSelection: selectedValue,
    );*/

    return DropdownButtonFormField(
      decoration: const InputDecoration(
        // labelText: 'Wallet Name',
        border: OutlineInputBorder(),
      ),
      style: context.bodyLarge,
      dropdownColor: Theme.of(context).colorScheme.surface,
      isExpanded: true,
      value: selectedValue,
      items: walletNamesExample.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            // style: context.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          selectedValue = value!;
        });
      },
    );
  }
}
