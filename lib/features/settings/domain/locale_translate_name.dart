import 'dart:ui';

String translateLocaleName(Locale locale) {
  switch (locale.languageCode) {
    case 'zh':
      return '中文';
    case 'de':
      return 'Deutsch';
    case 'en':
      return 'English';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    case 'it':
      return 'Italiano';
    case 'ja':
      return '日本語';
    case 'ko':
      return '한국어';
    case 'pt':
      return 'Português';
    case 'ru':
      return 'Русский';
    case 'tr':
      return 'Turkiye';
    case 'nl':
      return 'Nederlands';
    case 'bg':
      return 'Български';
    case 'hi':
      return 'हिंदी';
    case 'ms':
      return 'Melayu';
    case 'pl':
      return 'Polski';
    case 'uk':
      return 'українська';
    case 'ar':
      return 'العربية';
    default:
      return 'N/A';
  }
}
