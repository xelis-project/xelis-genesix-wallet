import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            logger.info('help section');
            break;
          case MenuItems.logout:
            _logout(ref);
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

  void _logout(WidgetRef ref) {
    logger.info('logout');
    ref.read(authenticationProvider.notifier).logout();
  }
}
