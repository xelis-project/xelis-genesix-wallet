import 'package:flutter/widgets.dart';
import 'package:jovial_svg/jovial_svg.dart';

class AppResources {
  static String localNodeAddress = '127.0.0.1:8080';
  static String officialNodeURL = 'node.xelis.io';
  static String officialDevNodeURL = 'dev-node.xelis.io';
  static String officialTestnetNodeURL = 'testnet-node.xelis.io';

  static List<String> builtInNodeAddresses = [
    localNodeAddress,
    officialNodeURL,
    officialDevNodeURL,
    officialTestnetNodeURL,
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
