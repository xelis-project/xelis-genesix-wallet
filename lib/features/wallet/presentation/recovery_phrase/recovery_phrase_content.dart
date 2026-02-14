import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';

class RecoveryPhraseContent extends ConsumerStatefulWidget {
  const RecoveryPhraseContent({super.key});

  @override
  ConsumerState createState() => _RecoveryPhraseContentState();
}

class _RecoveryPhraseContentState extends ConsumerState<RecoveryPhraseContent> {
  final _controller = ScrollController();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(Spaces.medium),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Spaces.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FIcons.triangleAlert,
                          color: context.theme.colors.primary,
                          size: 30,
                        ),
                        const SizedBox(width: Spaces.small),
                        Text(
                          loc.warning,
                          style: context.theme.typography.xl.copyWith(
                            color: context.theme.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    Text(
                      loc.seed_warning_message_1,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              FDivider(),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FSelectMenuTile<MnemonicLanguage>.builder(
                      title: Text(loc.language),
                      count: MnemonicLanguage.values.length,
                      selectControl: .managedRadio(
                        initial: MnemonicLanguage.english,
                        onChange: (values) {
                          final selected = values.isEmpty ? null : values.first;
                          if (selected == null) return;
                          ref
                              .read(walletStateProvider.notifier)
                              .getSeed(selected)
                              .then(
                                (words) {
                                  setState(() {
                                    _seedWords = words;
                                  });
                                },
                                onError: (_, _) => ref
                                    .read(toastProvider.notifier)
                                    .showError(description: loc.oups),
                              );
                        },
                      ),
                      detailsBuilder: (context, values, _) =>
                          Text(values.first.displayName),
                      menuBuilder: (context, index) => FSelectTile(
                        title: Text(MnemonicLanguage.values[index].displayName),
                        value: MnemonicLanguage.values[index],
                      ),
                    ),
                  ),
                  Spacer(),
                  FTooltip(
                    tipBuilder: (context, controller) {
                      return Text(loc.copy_recovery_phrase);
                    },
                    child: FButton.icon(
                      onPress: () => copyToClipboard(
                        _seedWords.join(" "),
                        ref,
                        loc.copied,
                      ),
                      child: const Icon(FIcons.copy, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spaces.extraLarge),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Spaces.small),
                  child: FadedScroll(
                    controller: _controller,
                    child: SingleChildScrollView(
                      controller: _controller,
                      child: Wrap(
                        spacing: Spaces.medium,
                        runSpacing: Spaces.medium,
                        children: List.generate(
                          _seedWords.length,
                          (i) => FBadge(
                            style: FBadgeStyle.secondary(),
                            child: Row(
                              children: [
                                Text(
                                  '${i + 1}.',
                                  style: context.theme.typography.sm.copyWith(
                                    color: context.theme.colors.primary,
                                  ),
                                ),
                                const SizedBox(width: Spaces.small),
                                Text(_seedWords[i]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
