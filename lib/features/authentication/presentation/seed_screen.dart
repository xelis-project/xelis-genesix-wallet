import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/data/seed_search_engine_repository.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/input_decoration.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';
import 'package:go_router/go_router.dart';

class SeedScreen extends ConsumerStatefulWidget {
  const SeedScreen({super.key});

  @override
  ConsumerState createState() => _SeedScreenState();
}

class _SeedScreenState extends ConsumerState<SeedScreen> {
  final _searchBarFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_searchBarFormKey');
  (String word, int index)? _selectedItem;
  int? _wordIndex;
  MnemonicLanguage _mnemonicLanguage = MnemonicLanguage.english;
  List<String>? _searchResults;
  final List<String> _recoveryPhrase = List.filled(25, '');
  List<String>? _invalidWords;
  late FocusNode _searchBarFocusNode;

  @override
  void initState() {
    super.initState();
    _searchBarFocusNode = FocusNode();
  }

  @override
  dispose() {
    _searchBarFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    final searchResults = AnimatedSwitcher(
      duration: const Duration(milliseconds: AppDurations.animNormal),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          axisAlignment: 1.0,
          child: child,
        );
      },
      child: _searchResults == null
          ? SizedBox.shrink(key: ValueKey(1))
          : SizedBox(
              key: ValueKey(2),
              height: 100,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black,
                    ],
                    stops: [0.0, 0.01, 0.1, 0.7, 0.95, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstOut,
                child: _searchResults!.isEmpty
                    ? Center(
                        child: Text(
                        loc.seed_error_searchbar_no_word_found,
                        style: context.bodyLarge,
                      ))
                    : Focus(
                        onFocusChange: _onSearchResultsChanged,
                        onKeyEvent: _onArrowKeysPressed,
                        child: ListView(
                          children: [
                            Wrap(
                              children: _searchResults!
                                  .map(
                                    (String word) => FittedBox(
                                      child: GestureDetector(
                                        onTap: () =>
                                            _addWordToRecoveryPhrase(word),
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: context.colors.surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _selectedItem?.$1 == word
                                                  ? context.colors.primary
                                                  : context.colors.surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              word,
                                              style: context.bodySmall,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
    );

    return CustomScaffold(
      appBar: GenericAppBar(title: loc.recovery_phrase),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: Spaces.large),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.seed_language_selector_title,
                        style: context.titleSmall
                            ?.copyWith(color: context.moreColors.mutedColor),
                      ),
                      const SizedBox(height: Spaces.extraSmall),
                      FormBuilderDropdown(
                        name: 'language',
                        initialValue: _mnemonicLanguage,
                        enableFeedback: true,
                        dropdownColor: context.colors.surface.withOpacity(0.9),
                        focusColor: context.colors.surface.withOpacity(0.9),
                        onChanged: _onLanguageChanged,
                        items: MnemonicLanguage.values
                            .map((MnemonicLanguage language) =>
                                DropdownMenuItem<MnemonicLanguage>(
                                  value: language,
                                  child: Text(language.displayName),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Column(
                  children: [
                    IconButton.filled(
                      onPressed: _pasteRecoveryPhrase,
                      icon: Icon(Icons.paste_rounded),
                      tooltip: loc.paste_all_button_tooltip,
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    Text(
                      loc.paste_all_button,
                      style: context.labelLarge
                          ?.copyWith(color: context.moreColors.mutedColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Spaces.extraLarge),
            FormBuilder(
              key: _searchBarFormKey,
              child: FormBuilderTextField(
                name: 'search_bar',
                focusNode: _searchBarFocusNode,
                style: context.bodyLarge,
                decoration: context.textInputDecoration.copyWith(
                  labelText: loc.seed_searchbar_label,
                  suffixIcon: IconButton(
                    onPressed: () => _searchBarFormKey.currentState?.reset(),
                    icon: Icon(Icons.close_rounded),
                  ),
                ),
                onChanged: _onSearchBarChanged,
              ),
            ),
            const SizedBox(height: Spaces.medium),
            searchResults,
            Divider(),
            const SizedBox(height: Spaces.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.your_recovery_phrase,
                  style: context
                      .titleMedium /*
                      ?.copyWith(color: context.moreColors.mutedColor)*/
                  ,
                ),
                if (_invalidWords?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: Spaces.small, left: Spaces.small),
                    child: FittedBox(
                      child: Tooltip(
                        message: loc.seed_error_invalid_words_detected,
                        child: Icon(
                          Icons.error_outline_rounded,
                          color: context.colors.error,
                        ),
                      ),
                    ),
                  ),
                Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: _clearRecoveryPhrase,
                  child: Text(
                    loc.clear_all_button,
                    style: context.labelLarge,
                  ),
                ),
              ],
            ),
            Focus(
              onKeyEvent: _onTabPressed,
              child: GridView.count(
                crossAxisCount: context.isHandset
                    ? 2
                    : context.isWideScreen
                        ? 5
                        : 3,
                // semanticChildCount: _currentRecoveryPhrase.length,
                childAspectRatio: 5,
                mainAxisSpacing: Spaces.none,
                crossAxisSpacing: Spaces.small,
                shrinkWrap: true,
                children: _recoveryPhrase.indexed
                    .map<Widget>(
                      ((int index, String word) tuple) => Padding(
                        padding: const EdgeInsets.all(Spaces.none),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedItem != null) {
                                _selectedItem = null;
                              }
                              if (_wordIndex == tuple.$1) {
                                _wordIndex = null;
                              } else {
                                _wordIndex = tuple.$1;
                              }
                            });
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: _wordIndex == tuple.$1
                                    ? context.colors.primary
                                    : _invalidWords?.contains(tuple.$2) ?? false
                                        ? context.colors.error
                                        : context.moreColors.mutedColor,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: Spaces.medium, right: Spaces.medium),
                              child: Row(
                                children: [
                                  Text(
                                    '${tuple.$1 + 1}',
                                    style: context.bodyLarge?.copyWith(
                                        color: context.colors.primary),
                                  ),
                                  const SizedBox(width: Spaces.small),
                                  Text(
                                    tuple.$2,
                                    style: context.titleMedium,
                                  )
                                ],
                              ),
                            ),
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
      floatingActionButton: SizedBox(
        height: 40,
        child: FloatingActionButton.extended(
          onPressed: _continue,
          label: Text(
            loc.continue_button,
          ),
          icon: Icon(Icons.arrow_forward_rounded),
        ),
      ),
    );
  }

  void _addWordToRecoveryPhrase(String word) {
    setState(() {
      _selectedItem = (word, _searchResults!.indexOf(word));

      if (_wordIndex == null) {
        _selectedItem = null;
        return;
      }
      // Remove the invalid word from the list of invalid words
      if (_invalidWords?.contains(_recoveryPhrase[_wordIndex!]) ?? false) {
        _invalidWords!.remove(_recoveryPhrase[_wordIndex!]);
      }

      // Add the selected word from the search results to the recovery phrase
      _recoveryPhrase[_wordIndex!] = _selectedItem!.$1;

      // Select the next empty word in the recovery phrase
      if (_wordIndex! < _recoveryPhrase.length - 1) {
        _wordIndex = _wordIndex! + 1;
      } else {
        _wordIndex = null;
        _selectedItem = null;
      }

      // Clear the search results
      Future.delayed(Duration(milliseconds: 100), () {
        _searchResults = null;
        _selectedItem = null;
        _searchBarFormKey.currentState?.reset();
        _searchBarFocusNode.requestFocus();
      });
    });
  }

  void _pasteRecoveryPhrase() {
    final loc = ref.read(appLocalizationsProvider);
    Clipboard.getData('text/plain').then((ClipboardData? data) {
      if (data == null || data.text == null || data.text!.trim().isEmpty) {
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.seed_error_clipboard_empty);
        return;
      }

      final List<String> words =
          data.text!.split(' ').map((word) => word.trim()).toList();

      if (words.length > 25) {
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.seed_error_too_many_words);
        return;
      }

      setState(() {
        _clearRecoveryPhrase();
        _recoveryPhrase.setAll(0, words);
        final SeedSearchEngineRepository searchEngineRepository =
            SeedSearchEngineRepository(_mnemonicLanguage);
        _invalidWords = searchEngineRepository.checkSeed(_recoveryPhrase);
      });
    });
  }

  void _clearRecoveryPhrase() {
    setState(() {
      _recoveryPhrase.fillRange(0, _recoveryPhrase.length, '');
      _invalidWords = null;
      _selectedItem = null;
      _wordIndex = null;
    });
  }

  void _onLanguageChanged(MnemonicLanguage? value) {
    setState(() {
      _mnemonicLanguage = value ?? MnemonicLanguage.english;
      _searchResults = null;
      _searchBarFormKey.currentState?.reset();
      _clearRecoveryPhrase();
    });
  }

  void _continue() {
    final loc = ref.read(appLocalizationsProvider);
    if (_invalidWords != null && _invalidWords!.isNotEmpty) {
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError(loc.seed_error_invalid_words);
      return;
    }
    if (_recoveryPhrase.any((word) => word.isEmpty) ||
        _recoveryPhrase.length < 24) {
      ref
          .read(snackBarMessengerProvider.notifier)
          .showError(loc.seed_error_phrase_incomplete);
      return;
    }

    context.push(AppScreen.recoverWalletFromSeed2.toPath,
        extra: _recoveryPhrase);
  }

  void _onSearchBarChanged(String? value) {
    setState(() {
      if (value?.isEmpty ?? true) {
        _searchResults = null;
        return;
      }

      final SeedSearchEngineRepository searchEngineRepository =
          SeedSearchEngineRepository(_mnemonicLanguage);
      _searchResults = searchEngineRepository.search(value ?? '');
    });
  }

  KeyEventResult _onArrowKeysPressed(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_searchResults != null && _searchResults!.isNotEmpty) {
          setState(() {
            final int index = _selectedItem!.$2 + 1;
            if (index < _searchResults!.length) {
              _selectedItem = (_searchResults![index], index);
            }
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_searchResults != null && _searchResults!.isNotEmpty) {
          setState(() {
            final int index = _selectedItem!.$2 - 1;
            if (index >= 0) {
              _selectedItem = (_searchResults![index], index);
            }
          });
        }
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_selectedItem != null) {
          _addWordToRecoveryPhrase(_selectedItem!.$1);
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onSearchResultsChanged(bool hasFocus) {
    if (hasFocus &&
        _selectedItem == null &&
        _searchResults != null &&
        _searchResults!.isNotEmpty) {
      setState(() {
        _selectedItem = (_searchResults!.first, 0);
        _wordIndex = _recoveryPhrase.indexOf('');
      });
    }
  }

  KeyEventResult _onTabPressed(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        setState(() {
          if (_wordIndex == null) {
            _wordIndex = 0;
          } else if (_wordIndex! < _recoveryPhrase.length - 1) {
            _wordIndex = _wordIndex! + 1;
          } else {
            _wordIndex = null;
          }
        });
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
