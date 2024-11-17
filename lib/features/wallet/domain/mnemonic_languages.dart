enum MnemonicLanguage {
  english(0, 'English'),
  french(1, 'French'),
  italian(2, 'Italian'),
  spanish(3, 'Spanish'),
  portuguese(4, 'Portuguese'),
  japanese(5, 'Japanese'),
  chineseSimplified(6, 'Chinese Simplified'),
  russian(7, 'Russian'),
  esperanto(8, 'Esperanto'),
  dutch(9, 'Dutch'),
  german(10, 'German');

  final int rustIndex;
  final String displayName;

  const MnemonicLanguage(this.rustIndex, this.displayName);
}
