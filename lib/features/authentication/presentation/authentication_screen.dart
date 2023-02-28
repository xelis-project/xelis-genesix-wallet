import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/create_wallet_widget.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/open_wallet_widget.dart';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';
import 'package:xelis_mobile_wallet/shared/widgets/brightness_toggle.dart';
import 'package:xelis_mobile_wallet/shared/widgets/popup_menu.dart';

class AuthenticationScreen extends ConsumerWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          // title: const Text('Xelis Wallet'),
          title: AppResources.logoXelisHorizontal,
          automaticallyImplyLeading: false,
          actions: const [
            BrightnessToggle(),
            PopupMenu(),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(
                text: 'Open',
                icon: Icon(Icons.lock_open_outlined),
              ),
              Tab(
                text: 'Create',
                icon: Icon(Icons.add_circle_outline_outlined),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OpenWalletWidget(),
            CreateWalletWidget(),
          ],
        ),
      ),
    );
  }
}
