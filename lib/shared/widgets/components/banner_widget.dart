import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/screens/settings/domain/settings_state.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

ScalableImageWidget getBanner(BuildContext context, AppTheme theme) {
  return switch (theme) {
    AppTheme.light => AppResources.svgBannerGreenWidget,
    AppTheme.dark => AppResources.svgBannerWhiteWidget,
    AppTheme.xelis => AppResources.svgBannerWhiteWidget,
  };
}
