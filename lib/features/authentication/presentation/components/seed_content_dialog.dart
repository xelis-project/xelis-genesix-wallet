import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';

class SeedContentDialog extends ConsumerStatefulWidget {
  const SeedContentDialog(this.seed, {super.key});

  final List<String> seed;

  @override
  ConsumerState<SeedContentDialog> createState() => _SeedContentDialogState();
}

class _SeedContentDialogState extends ConsumerState<SeedContentDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return GenericDialog(
      scrollable: false,
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      '${loc.recovery_phrase.toLowerCase().capitalize()}:',
                      style: context.titleLarge,
                    ),
                  ),
                  IconButton.outlined(
                    onPressed:
                        () => copyToClipboard(
                          widget.seed.join(" "),
                          ref,
                          loc.copied,
                        ),
                    icon: Icon(Icons.copy, size: 18),
                    tooltip: loc.copy_recovery_phrase,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spaces.small),
            Expanded(
              child: GridView.count(
                crossAxisCount: context.isHandset ? 2 : 3,
                semanticChildCount: widget.seed.length,
                childAspectRatio: 5,
                mainAxisSpacing: Spaces.none,
                crossAxisSpacing: Spaces.small,
                shrinkWrap: true,
                children:
                    widget.seed.indexed
                        .map<Widget>(
                          ((int index, String word) tuple) => Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: Spaces.medium,
                                right: Spaces.medium,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${tuple.$1 + 1}',
                                        style: context.bodyLarge?.copyWith(
                                          color: context.colors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        tuple.$2,
                                        style: context.titleMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: Spaces.large),
            FormBuilderCheckbox(
              name: 'confirm',
              title: Text(
                'I confirm that I have written down my recovery phrase and understand the risks of sharing it.',
                style: context.bodyMedium,
              ),
              validator: FormBuilderValidators.required(
                errorText: loc.field_required_error,
              ),
              onChanged: (value) {
                setState(() {
                  _confirmed = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _confirmed
                  ? () {
                    Navigator.pop(context);
                  }
                  : null,
          child: Text(loc.continue_button),
        ),
      ],
    );
  }
}
