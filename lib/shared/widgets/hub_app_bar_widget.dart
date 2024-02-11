import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class HubAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HubAppBar({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    context.loaderOverlay.show();
    await ref.read(authenticationProvider.notifier).logout();
    if (!context.mounted) return;
    context.loaderOverlay.hide();
  }

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
      actions: [
        // const PopupMenu(),
        IconButton(
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
