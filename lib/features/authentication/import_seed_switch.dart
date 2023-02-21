import 'package:flutter/material.dart';
import 'package:xelis_wallet_app/shared/theme/extensions.dart';

class ImportSeedSwitch extends StatefulWidget {
  const ImportSeedSwitch({super.key});

  @override
  State<ImportSeedSwitch> createState() => _ImportSeedSwitchState();
}

class _ImportSeedSwitchState extends State<ImportSeedSwitch> {
  bool importSeed = false;

  final MaterialStateProperty<Icon?> thumbIcon =
      MaterialStateProperty.resolveWith<Icon?>(
    (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  @override
  Widget build(BuildContext context) {
    final selector = Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            'Import your seed',
            style: context.bodyLarge,
          ),
        ),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: importSeed,
          onChanged: (value) {
            setState(() {
              importSeed = value;
            });
            // if (value) {
            //   _dialogBuilder(context);
            // }
          },
        ),
      ],
    );

    final seedInput = TextFormField(
      decoration: const InputDecoration(
        labelText: 'Seed',
        border: OutlineInputBorder(),
      ),
    );

    return Column(
      children: [
        selector,
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: importSeed ? 50 : 0,
          curve: Curves.easeInOut,
          child: importSeed ? seedInput : const SizedBox.shrink(),
        ),
      ],
    );
  }

/*Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seed'),
          content: Padding(
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              decoration: const InputDecoration(
                // labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  importSeed = false;
                });
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }*/
}
