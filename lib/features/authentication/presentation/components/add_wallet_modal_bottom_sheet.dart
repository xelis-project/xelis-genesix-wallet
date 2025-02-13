import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

class AddWalletModalBottomSheetMenu extends ConsumerStatefulWidget {
  const AddWalletModalBottomSheetMenu({super.key});

  @override
  ConsumerState<AddWalletModalBottomSheetMenu> createState() =>
      _AddWalletModalBottomSheetMenuState();
}

class _AddWalletModalBottomSheetMenuState
    extends ConsumerState<AddWalletModalBottomSheetMenu> {
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          title: Center(
            child: Text(
              loc.create_new_wallet,
              style: context.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          onTap: () {
            context.pop();
            context.push(AppScreen.createNewWallet.toPath);
          },
        ),
        ListTile(
          title: Center(
            child: Text(
              loc.recover_from_recovery_phrase,
              style: context.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          onTap: () {
            context.pop();
            context.push(AppScreen.recoverWalletFromSeed1.toPath);
          },
        ),
        ListTile(
          title: Center(
            child: Text(
              loc.recover_from_private_key,
              style: context.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          onTap: () {
            context.pop();
            context.push(AppScreen.recoverWalletFromPrivateKey.toPath);
          },
        ),
        if (isDesktopDevice)
          ListTile(
            title: Center(
              child: Text(
                loc.import_wallet_folder,
                style: context.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            onTap: () => _importWalletFolder(),
          ),
        Padding(
          padding: const EdgeInsets.all(Spaces.medium),
          child: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }

  // only used for desktop wallet import
  void _importWalletFolder() async {
    final loc = ref.read(appLocalizationsProvider);
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      if (await isWalletFolderValid(path)) {
        final walletName = path.split(p.separator).last;
        final walletsDir = await getAppWalletsDirPath();
        final network = ref.read(settingsProvider).network;

        final walletExists =
            await Directory(
              p.join(walletsDir, network.name, walletName),
            ).exists();
        if (walletExists) {
          ref
              .read(snackBarMessengerProvider.notifier)
              .showError(loc.wallet_already_exists);
        } else {
          if (mounted) {
            final record = (path: path, walletName: walletName);
            context.pop(record);
          }
        }
      } else {
        ref
            .read(snackBarMessengerProvider.notifier)
            .showError(loc.invalid_wallet_folder);
      }
    }
  }
}
