import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class QrDialog extends ConsumerWidget {
  const QrDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletSnapshot = ref.watch(walletStateProvider);

    // final userThemeMode = ref.watch(userThemeModeProvider);

    // var iconTarget = '';
    // switch (userThemeMode.themeMode) {
    //   case ThemeMode.system:
    //     if (context.mediaQueryData.platformBrightness == Brightness.light) {
    //       iconTarget = AppResources.svgIconWhiteTarget;
    //     } else {
    //       iconTarget = AppResources.svgIconBlackTarget;
    //     }
    //   case ThemeMode.light:
    //     iconTarget = AppResources.svgIconWhiteTarget;
    //   case ThemeMode.dark:
    //     iconTarget = AppResources.svgIconBlackTarget;
    // }

    return AlertDialog(
      scrollable: true,
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'QR Code',
          style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      content: PrettyQrView.data(
        data: walletSnapshot.address,
        decoration: PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(color: context.colors.onBackground),
          // image: PrettyQrDecorationImage(
          //   image: Image.network(iconTarget).image,
          // ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => context.pop(),
          child: Text(loc.ok_button),
        ),
      ],
    );
  }
}
