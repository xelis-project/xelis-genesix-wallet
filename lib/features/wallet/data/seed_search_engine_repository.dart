import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class SeedSearchEngineRepository {
  SeedSearchEngineRepository._internal(this._searchEngine);

  final SeedSearchEngine _searchEngine;

  static final Map<MnemonicLanguage, SeedSearchEngineRepository> _cache =
      <MnemonicLanguage, SeedSearchEngineRepository>{};

  factory SeedSearchEngineRepository(MnemonicLanguage language) {
    return _cache.putIfAbsent(
      language,
      () => SeedSearchEngineRepository._internal(
        XelisWalletFlutter.createSeedSearchEngine(
          language: language.seedLanguage,
        ),
      ),
    );
  }

  factory SeedSearchEngineRepository.initEnglish() {
    return SeedSearchEngineRepository(MnemonicLanguage.english);
  }

  factory SeedSearchEngineRepository.initFrench() {
    return SeedSearchEngineRepository(MnemonicLanguage.french);
  }

  factory SeedSearchEngineRepository.initItalian() {
    return SeedSearchEngineRepository(MnemonicLanguage.italian);
  }

  factory SeedSearchEngineRepository.initSpanish() {
    return SeedSearchEngineRepository(MnemonicLanguage.spanish);
  }

  factory SeedSearchEngineRepository.initPortuguese() {
    return SeedSearchEngineRepository(MnemonicLanguage.portuguese);
  }

  factory SeedSearchEngineRepository.initJapanese() {
    return SeedSearchEngineRepository(MnemonicLanguage.japanese);
  }

  factory SeedSearchEngineRepository.initChineseSimplified() {
    return SeedSearchEngineRepository(MnemonicLanguage.chineseSimplified);
  }

  factory SeedSearchEngineRepository.initRussian() {
    return SeedSearchEngineRepository(MnemonicLanguage.russian);
  }

  factory SeedSearchEngineRepository.initEsperanto() {
    return SeedSearchEngineRepository(MnemonicLanguage.esperanto);
  }

  factory SeedSearchEngineRepository.initDutch() {
    return SeedSearchEngineRepository(MnemonicLanguage.dutch);
  }

  factory SeedSearchEngineRepository.initGerman() {
    return SeedSearchEngineRepository(MnemonicLanguage.german);
  }

  List<String> search(String input) {
    return _searchEngine.search(query: input);
  }

  // Check if the seed is valid and return the list of invalid words
  List<String> checkSeed(List<String> seed) {
    return _searchEngine.findInvalidWords(words: seed);
  }
}
