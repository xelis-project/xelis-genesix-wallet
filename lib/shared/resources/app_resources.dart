import 'package:flutter/widgets.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/screens/wallet/domain/node_address.dart';

class AppResources {
  static const String xelisWalletName = 'XELIS Wallet';

  static const int xelisDecimals = 8;

  static List<NodeAddress> mainnetNodes = [
    const NodeAddress(
      name: 'Official XELIS Mainnet',
      url: 'https://$mainnetNodeURL',
    ),
  ];

  static List<NodeAddress> testnetNodes = [
    const NodeAddress(
      name: 'Official XELIS Testnet',
      url: 'https://$testnetNodeURL',
    )
  ];

  static List<NodeAddress> devNodes = [
    const NodeAddress(
      name: 'Default Local Node',
      url: 'http://$localhostAddress',
    ),
  ];

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

  static String svgBannerGreenPath =
      'assets/banners/svg/transparent_background_green_logo.svg';
  static String svgBannerBlackPath =
      'assets/banners/svg/transparent_background_black_logo.svg';
  static String svgBannerWhitePath =
      'assets/banners/svg/transparent_background_white_logo.svg';
  static String bgDotsPath = 'assets/bg_dots.png';

  static late ScalableImage svgBannerGreen;
  static late ScalableImage svgBannerWhite;
  static late ScalableImage svgBannerBlack;
  static late Image bgDots;

  static ScalableImageWidget svgBannerGreenWidget = ScalableImageWidget(
    si: AppResources.svgBannerGreen,
    scale: 0.15,
  );

  static ScalableImageWidget svgBannerBlackWidget = ScalableImageWidget(
    si: AppResources.svgBannerBlack,
    scale: 0.15,
  );

  static ScalableImageWidget svgBannerWhiteWidget = ScalableImageWidget(
    si: AppResources.svgBannerWhite,
    scale: 0.15,
  );
}
