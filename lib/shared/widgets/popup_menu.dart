import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

enum MenuItems {
  settings,
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
          case MenuItems.settings:
            _settings(context);
            break;
          case MenuItems.help:
            logger.info('help');
            break;
          case MenuItems.logout:
            _logout(ref);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuItems>>[
        const PopupMenuItem<MenuItems>(
          value: MenuItems.settings,
          child: Text('Settings'),
        ),
        const PopupMenuItem<MenuItems>(
          value: MenuItems.help,
          child: Text('Help'),
        ),
        const PopupMenuItem<MenuItems>(
          value: MenuItems.logout,
          child: Text('Logout'),
        ),
      ],
    );
  }

  void _settings(BuildContext context) {
    context.push(AppScreen.settings.toPath);
  }

  void _logout(WidgetRef ref) {
    ref.read(authenticationNotifierProvider.notifier).logout();
  }
}
