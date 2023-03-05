import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/router/route_utils.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
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
            logger.info('help section');
            break;
          case MenuItems.logout:
            _logout(ref);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final loc = ref.watch(appLocalizationsProvider);
        final auth = ref.watch(authenticationNotifierProvider);
        return <PopupMenuEntry<MenuItems>>[
          PopupMenuItem<MenuItems>(
            value: MenuItems.settings,
            child: Text(loc.settings),
          ),
          PopupMenuItem<MenuItems>(
            value: MenuItems.help,
            child: Text(loc.help),
          ),
          PopupMenuItem<MenuItems>(
            enabled: auth,
            value: MenuItems.logout,
            child: Text(loc.logout),
          ),
        ];
      },
    );
  }

  void _settings(BuildContext context) {
    context.push(AppScreen.settings.toPath);
  }

  void _logout(WidgetRef ref) {
    ref.read(authenticationNotifierProvider.notifier).logout();
  }
}
