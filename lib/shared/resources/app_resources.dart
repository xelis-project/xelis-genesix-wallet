import 'package:country_flags/country_flags.dart';
import 'package:flutter/widgets.dart';
import 'package:genesix/features/wallet/domain/asset.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
// import 'package:jovial_svg/jovial_svg.dart';

class AppResources {
  static const String xelisWalletName = 'Genesix';

  static const String userWalletsFolderName = 'Genesix wallets';

  static const String zeroBalance = '0.00000000';

  static const Map<String, String> defaultAssets = {
    sdk.xelisAsset: zeroBalance,
  };

  static const int xelisDecimals = 8;

  static const Asset xelisAsset = Asset(
    hash: sdk.xelisAsset,
    name: 'XELIS',
    imagePath: greenBackgroundBlackIconPath,
    // imageURL:
    //     "https://raw.githubusercontent.com/xelis-project/xelis-assets/master/icons/png/circle/green_background_black_logo.png",
    decimals: xelisDecimals,
    ticker: 'XEL',
  );

  static List<NodeAddress> mainnetNodes = [
    // const NodeAddress(
    //   name: 'Official Seed Node #1',
    //   url: 'https://${sdk.mainnetNodeURL}',
    // ),
    const NodeAddress(
      name: 'Seed Node US #1',
      url: 'https://us-node.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node France #1',
      url: 'https://fr-node.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Germany #1',
      url: 'https://de-node.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Poland #1',
      url: 'https://pl-node.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Singapore #1',
      url: 'https://sg-node.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node United Kingdom #1',
      url: 'https://uk-node.xelis.io/',
    ),
    const NodeAddress(
      name: 'Seed Node Canada #1',
      url: 'https://ca-node.xelis.io/',
    ),
  ];

  static List<NodeAddress> testnetNodes = [
    const NodeAddress(
      name: 'Official XELIS Testnet',
      url: 'https://${sdk.testnetNodeURL}',
    ),
  ];

  static List<NodeAddress> devNodes = [
    const NodeAddress(
      name: 'Default Local Node',
      url: 'http://${sdk.localhostAddress}',
    ),
  ];

  static String explorerMainnetUrl = 'https://explorer.xelis.io/';
  static String explorerTestnetUrl = 'https://testnet-explorer.xelis.io/';

  /*static String svgIconGreenTarget =
      'https://raw.githubusercontent.com/xelis-project/xelis-assets/master/icons/svg/transparent/green.svg';
  static String svgIconBlackTarget =
      'https://raw.githubusercontent.com/xelis-project/xelis-assets/master/icons/svg/transparent/black.svg';
  static String svgIconWhiteTarget =
      'https://raw.githubusercontent.com/xelis-project/xelis-assets/master/icons/svg/transparent/white.svg';

  static late ScalableImage svgIconGreen;
  static late ScalableImage svgIconWhite;
  static late ScalableImage svgIconBlack;

  static ScalableImageWidget svgIconGreenWidget = ScalableImageWidget(
    si: AppResources.svgIconGreen,
    scale: 0.06,
  );

  static ScalableImageWidget svgIconBlackWidget = ScalableImageWidget(
    si: AppResources.svgIconBlack,
    scale: 0.06,
  );

  static ScalableImageWidget svgIconWhiteWidget = ScalableImageWidget(
    si: AppResources.svgIconWhite,
    scale: 0.06,
  );*/

  // static String svgBannerGreenPath =
  //     'assets/banners/svg/transparent_background_green_logo.svg';
  // static String svgBannerBlackPath =
  //     'assets/banners/svg/transparent_background_black_logo.svg';
  // static String svgBannerWhitePath =
  //     'assets/banners/svg/transparent_background_white_logo.svg';
  static const String greenBackgroundBlackIconPath =
      'assets/icons/png/circle/green_background_black_logo.png';
  static const String bgDotsPath = 'assets/bg_dots.png';

  // static late ScalableImage svgBannerGreen;
  // static late ScalableImage svgBannerWhite;
  // static late ScalableImage svgBannerBlack;
  static late Image bgDots;

  // static ScalableImageWidget svgBannerGreenWidget = ScalableImageWidget(
  //   si: AppResources.svgBannerGreen,
  //   scale: 0.15,
  // );
  //
  // static ScalableImageWidget svgBannerBlackWidget = ScalableImageWidget(
  //   si: AppResources.svgBannerBlack,
  //   scale: 0.15,
  // );
  //
  // static ScalableImageWidget svgBannerWhiteWidget = ScalableImageWidget(
  //   si: AppResources.svgBannerWhite,
  //   scale: 0.15,
  // );

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
