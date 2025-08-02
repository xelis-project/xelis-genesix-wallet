import 'package:country_flags/country_flags.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

class AppResources {
  static const String xelisWalletName = 'Genesix';

  static const String userWalletsFolderName = 'Genesix wallets';

  static const String zeroBalance = '0.00000000';

  static const String xelisHash = sdk.xelisAsset;

  static const String xelisName = 'XELIS';

  static const int xelisDecimals = 8;

  static List<NodeAddress> mainnetNodes = [
    const NodeAddress(
      name: 'Seed Node US #1',
      url: 'https://us-network.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node France #1',
      url: 'https://fr-network.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Germany #1',
      url: 'https://de-network.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Poland #1',
      url: 'https://pl-network.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Singapore #1',
      url: 'https://sg-network.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node United Kingdom #1',
      url: 'https://uk-network.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Canada #1',
      url: 'https://ca-network.xelis.io/',
    ),
  ];

  static List<NodeAddress> testnetNodes = [
    const NodeAddress(
      name: 'Official XELIS Testnet',
      url: 'https://${sdk.testnetNodeURL}',
    ),
  ];

  static List<NodeAddress> devnetNodes = [
    const NodeAddress(
      name: 'Default Local Node',
      url: 'http://${sdk.localhostAddress}',
    ),
    const NodeAddress(
      name: 'Android simulator localhost',
      url: 'http://10.0.2.2:8080',
    ),
  ];

  static List<NodeAddress> stagenetNodes = [
    const NodeAddress(
      name: 'Default Local Node',
      url: 'http://${sdk.localhostAddress}',
    ),
  ];

  static String explorerMainnetUrl = 'https://explorer.xelis.io/';
  static String explorerTestnetUrl = 'https://testnet-explorer.xelis.io/';

  static late ScalableImage svgGenesixWalletOneLineWhite;
  static late ScalableImage svgGenesixWalletOneLineBlack;

  static const String greenBackgroundBlackIconPath =
      'assets/icons/png/circle/green_background_black_logo.png';
  static const String genesixWalletOneLineWhitePath =
      'assets/genesix/svg/genesix-wallet-one-line_white.svg';
  static const String genesixWalletOneLineBlackPath =
      'assets/genesix/svg/genesix-wallet-one-line_black.svg';

  static List<CountryFlag> countryFlags = List.generate(
    AppLocalizations.supportedLocales.length,
    (int index) {
      String languageCode =
          AppLocalizations.supportedLocales[index].languageCode;
      switch (languageCode) {
        case 'zh':
          return CountryFlag.fromCountryCode(
            'CN',
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
        case 'ru' || 'pt' || 'nl' || 'pl':
          return CountryFlag.fromCountryCode(
            languageCode,
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
        case 'ko':
          return CountryFlag.fromCountryCode(
            'KR',
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
        case 'ms':
          return CountryFlag.fromCountryCode(
            'MY',
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
        case 'uk':
          return CountryFlag.fromCountryCode(
            'UA',
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
        case 'ja':
          return CountryFlag.fromCountryCode(
            'JP',
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
        case 'ar':
          return CountryFlag.fromCountryCode(
            'SA',
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
        default:
          return CountryFlag.fromLanguageCode(
            AppLocalizations.supportedLocales[index].languageCode,
            height: 24,
            width: 30,
            shape: const RoundedRectangle(8),
          );
      }
    },
    growable: false,
  );
}
