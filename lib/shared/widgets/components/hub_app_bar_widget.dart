import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class HubAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HubAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletStateProvider);
    final loc = ref.watch(appLocalizationsProvider);
    return AppBar(
      leading: Tooltip(
        message: walletState.isOnline ? loc.connected : loc.disconnected,
        child: DotsIndicator(
          dotsCount: 1,
          decorator: DotsDecorator(
              activeColor: walletState.isOnline
                  ? context.colors.primary
                  : context.colors.error),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
