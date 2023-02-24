import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xelis_mobile_wallet/features/authentication/import_seed_switch.dart';
import 'package:xelis_mobile_wallet/features/authentication/providers/authentication_service.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/ressources/app_ressources.dart';
import 'package:xelis_mobile_wallet/shared/views/brightness_toggle.dart';
import 'package:xelis_mobile_wallet/shared/views/dropdown_wallet_name_menu.dart';
import 'package:xelis_mobile_wallet/shared/views/popup_menu.dart';

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        body: TabBarView(
          children: [
            Center(
              child: SizedBox(
                width: 300,
                // height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: DropdownWalletNameMenu(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Consumer(
                        builder: (
                          context,
                          ref,
                          child,
                        ) {
                          return OutlinedButton(
                            onPressed: () {
                              logger.info('Open wallet');
                              ref
                                  .read(authenticationNotifierProvider.notifier)
                                  .login();
                            },
                            child: const Text('Open wallet'),
                          );
                        },
                        // child: OutlinedButton(
                        //   onPressed: () {
                        //     logger.info('Open wallet');
                        //   },
                        //   child: const Text('Open wallet'),
                        // ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: 300,
                // height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hero(
                    //   tag: 'logo',
                    //   child: SizedBox(
                    //     height: 150,
                    //     child: AppResources.logoXelis,
                    //   ),
                    // ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: ImportSeedSwitch(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Wallet Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Consumer(
                        builder: (
                          context,
                          ref,
                          child,
                        ) {
                          return OutlinedButton(
                            onPressed: () {
                              logger.info('Create wallet');
                              ref
                                  .read(authenticationNotifierProvider.notifier)
                                  .login();
                            },
                            child: const Text('Create wallet'),
                          );
                        },
                        // child: OutlinedButton(
                        //   onPressed: () {
                        //     logger.info('Create wallet');
                        //   },
                        //   child: const Text('Create wallet'),
                        // ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
