import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget_old.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown_old.dart';

class MySeedScreen extends ConsumerStatefulWidget {
  const MySeedScreen({super.key});

  @override
  ConsumerState<MySeedScreen> createState() => _MySeedScreenState();
}

class _MySeedScreenState extends ConsumerState<MySeedScreen> {
  List<String> _seedWords = [];

  @override
  void initState() {
    super.initState();
    final loc = ref.read(appLocalizationsProvider);

    ref
        .read(walletStateProvider.notifier)
        .getSeed(MnemonicLanguage.english)
        .then(
          (words) {
            setState(() {
              _seedWords = words;
            });
          },
          onError: (_, _) =>
              ref.read(toastProvider.notifier).showError(description: loc.oups),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return CustomScaffold(
      backgroundColor: Colors.transparent,
      appBar: GenericAppBar(),
      body: Center(
        child: SizedBox(
          width: 800,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spaces.large),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.colors.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Spaces.medium),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: context.colors.primary,
                                    size: 30,
                                  ),
                                  const SizedBox(width: Spaces.medium),
                                  Text(
                                    loc.warning,
                                    style: context.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Spaces.extraSmall),
                              SelectableText(
                                loc.seed_warning_message_1,
                                style: context.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Spaces.large * 2),
                Row(
                  children: [
                    Expanded(
                      child: GenericFormBuilderDropdown(
                        name: 'languages_dropdown',
                        initialValue: MnemonicLanguage.english,
                        items: MnemonicLanguage.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (MnemonicLanguage? value) {
                          ref
                              .read(walletStateProvider.notifier)
                              .getSeed(value!)
                              .then(
                                (value) {
                                  setState(() {
                                    _seedWords = value;
                                  });
                                },
                                onError: (_, _) => ref
                                    .read(toastProvider.notifier)
                                    .showError(description: loc.oups),
                              );
                        },
                      ),
                    ),
                    Spacer(),
                    Column(
                      children: [
                        IconButton.filled(
                          onPressed: () => copyToClipboard(
                            _seedWords.join(" "),
                            ref,
                            loc.copied,
                          ),
                          icon: Icon(Icons.copy),
                          tooltip: loc.copy_recovery_phrase,
                        ),
                        const SizedBox(height: Spaces.extraSmall),
                        Text(
                          loc.copy,
                          style: context.labelLarge?.copyWith(
                            color: context.moreColors.mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Spaces.large),
                Text(loc.seed_warning_message_2, style: context.titleMedium),
                const SizedBox(height: Spaces.small),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: context.isHandset ? 2 : 3,
                    semanticChildCount: _seedWords.length,
                    childAspectRatio: 5,
                    mainAxisSpacing: Spaces.none,
                    crossAxisSpacing: Spaces.small,
                    shrinkWrap: true,
                    children: _seedWords.indexed
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
