import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:jovial_svg/jovial_svg.dart';

class AppResources {
  static List<String> builtInNodeAddresses = [
    mainnetNodeURL,
    testnetNodeURL,
    devNodeURL,
    localhostAddress,
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
}
