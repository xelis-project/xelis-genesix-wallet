import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    show SeedLanguage;

enum MnemonicLanguage {
  english(SeedLanguage.english, 'English'),
  french(SeedLanguage.french, 'French'),
  italian(SeedLanguage.italian, 'Italian'),
  spanish(SeedLanguage.spanish, 'Spanish'),
  portuguese(SeedLanguage.portuguese, 'Portuguese'),
  japanese(SeedLanguage.japanese, 'Japanese'),
  chineseSimplified(SeedLanguage.chineseSimplified, 'Chinese Simplified'),
  russian(SeedLanguage.russian, 'Russian'),
  esperanto(SeedLanguage.esperanto, 'Esperanto'),
  dutch(SeedLanguage.dutch, 'Dutch'),
  german(SeedLanguage.german, 'German');

  final SeedLanguage seedLanguage;
  final String displayName;

  const MnemonicLanguage(this.seedLanguage, this.displayName);
}
