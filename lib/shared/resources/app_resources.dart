import 'package:flutter/foundation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/node_address.dart';

class AppResources {
  static List<NodeAddress> builtInNodeAddresses = [
    // localhost simulator
    if (kDebugMode)
      const NodeAddress(
          name: 'Local Node for AS simulator', url: '10.0.2.2:8080'),
    const NodeAddress(name: 'Local Node', url: localhostAddress),
    const NodeAddress(
        name: 'Official xelis.io Mainnet',
        url: 'ws://$mainnetNodeURL/json_rpc'),
    const NodeAddress(
        name: 'Official xelis.io Testnet', url: 'ws://$testnetNodeURL/json_rpc')
  ];

  static String svgIconGreenTarget =
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
  );

  static String svgBannerGreenTarget =
      'https://raw.githubusercontent.com/xelis-project/xelis-assets/master/banners/svg/transparent_background_green_logo.svg';
  static String svgBannerBlackTarget =
      'https://raw.githubusercontent.com/xelis-project/xelis-assets/master/banners/svg/transparent_background_black_logo.svg';
  static String svgBannerWhiteTarget =
      'https://raw.githubusercontent.com/xelis-project/xelis-assets/master/banners/svg/transparent_background_white_logo.svg';

  static late ScalableImage svgBannerGreen;
  static late ScalableImage svgBannerWhite;
  static late ScalableImage svgBannerBlack;

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
