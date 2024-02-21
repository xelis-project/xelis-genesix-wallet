import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

ScalableImageWidget getBanner(BuildContext context, ThemeMode themeMode) {
  return switch (themeMode) {
    ThemeMode.system => context.isDarkMode
        ? AppResources.svgBannerWhiteWidget
        : AppResources.svgBannerGreenWidget,
    ThemeMode.light => AppResources.svgBannerGreenWidget,
    ThemeMode.dark => AppResources.svgBannerWhiteWidget,
  };
}
