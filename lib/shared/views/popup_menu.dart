import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/authentication/providers/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';

enum MenuItem {
  // languages,
  settings,
  help,
  logout,
}

class PopupMenu extends ConsumerWidget {
  const PopupMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<MenuItem>(
      // initialValue: selectedMenu,
      onSelected: (MenuItem item) {
        switch (item) {
          // case MenuItem.languages:
          //   logger.info('languages');
          //   break;
          case MenuItem.settings:
            // logger.info('settings');
            _settings(context);
            break;
          case MenuItem.help:
            logger.info('help');
            break;
          case MenuItem.logout:
            // logger.info('logout');
            _logout(ref);
            break;
        }
        // setState(() {
        //   selectedMenu = item;
        // });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuItem>>[
        // const PopupMenuItem<MenuItem>(
        //   value: MenuItem.languages,
        //   child: Text('Languages'),
        // ),
        const PopupMenuItem<MenuItem>(
          value: MenuItem.settings,
          child: Text('Settings'),
        ),
        const PopupMenuItem<MenuItem>(
          value: MenuItem.help,
          child: Text('Help'),
        ),
        const PopupMenuItem<MenuItem>(
          value: MenuItem.logout,
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
