import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/theme_mode_state_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/banner_widget.dart';

class HubAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HubAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletStateProvider);
    final loc = ref.watch(appLocalizationsProvider);
    final userThemeMode = ref.watch(userThemeModeProvider);
    final ScalableImageWidget banner =
        getBanner(context, userThemeMode.themeMode);

    return AppBar(
      leading: Tooltip(
        message: walletState.isOnline ? loc.connected : loc.disconnected,
        child: Center(
          child: DotsIndicator(
            dotsCount: 1,
            decorator: DotsDecorator(
                activeColor: walletState.isOnline
                    ? context.colors.primary
                    : context.colors.error),
            onTap: (_) {
              ref.read(walletStateProvider.notifier).reconnect();
            },
          ),
        ),
      ),
      title: Hero(
        tag: 'banner',
        child: Center(child: SizedBox(height: 24, child: banner)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
