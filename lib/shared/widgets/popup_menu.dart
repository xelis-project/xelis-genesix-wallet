import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

enum MenuItems {
  help,
  logout,
}

class PopupMenu extends ConsumerWidget {
  const PopupMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<MenuItems>(
      onSelected: (MenuItems item) {
        switch (item) {
          case MenuItems.help:
            // TODO
            logger.info('help section');
            break;
          case MenuItems.logout:
            _logout(context, ref);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final loc = ref.watch(appLocalizationsProvider);
        return <PopupMenuEntry<MenuItems>>[
          PopupMenuItem<MenuItems>(
            value: MenuItems.help,
            child: Text(loc.help),
          ),
          PopupMenuItem<MenuItems>(
            value: MenuItems.logout,
            child: Text(loc.logout),
          ),
        ];
      },
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    context.loaderOverlay.show();
    await ref.read(authenticationProvider.notifier).logout();
    if (!context.mounted) return;
    context.loaderOverlay.hide();
  }
}
