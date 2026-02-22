import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/password_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:path/path.dart' as p;
import 'package:genesix/features/authentication/presentation/components/network_select_menu_tile.dart';

class RestoreFolderTab extends ConsumerStatefulWidget {
  const RestoreFolderTab({super.key});

  @override
  ConsumerState createState() => _RestoreFolderTabState();
}

class _RestoreFolderTabState extends ConsumerState<RestoreFolderTab> {
  ({String path, String walletName})? _selectedWalletFolder;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    bool showOpenButton =
        _selectedWalletFolder != null && _selectedWalletFolder!.path.isNotEmpty;

    return FCard(
      subtitle: Text(loc.restore_wallet_from_folder),
      child: Column(
        children: [
          const SizedBox(height: Spaces.medium),
          NetworkSelectMenuTile(
            onSelected: (_) {
              setState(() {
                _selectedWalletFolder = null;
              });
            },
          ),
          const SizedBox(height: Spaces.medium),
          FTooltip(
            tipBuilder: (context, controller) =>
                Text(loc.select_wallet_folder_restore),
            childAnchor: Alignment.bottomCenter,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _importWalletFolder,
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: Container(
                    color: Colors.transparent,
                    child: Icon(FIcons.download, size: 30),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: Duration(milliseconds: AppDurations.animNormal),
            transitionBuilder: (child, animation) {
              final slideTween = Tween<Offset>(
                begin: Offset(0, -0.15),
                end: Offset.zero,
              );
              return SlideTransition(
                position: animation.drive(slideTween),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: showOpenButton
                ? Column(
                    key: UniqueKey(),
                    children: [
                      const SizedBox(height: Spaces.large),
                      Row(
                        children: [
                          Icon(FIcons.folder),
                          const SizedBox(width: Spaces.small),
                          Expanded(
                            child: Text(' ${_selectedWalletFolder!.path}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spaces.large),
                      FButton(
                        onPress: () {
                          _openImportedWallet();
                        },
                        child: Text(loc.open_button),
                      ),
                    ],
                  )
                : SizedBox.shrink(key: UniqueKey()),
          ),
        ],
      ),
    );
  }

  void _importWalletFolder() async {
    final loc = ref.read(appLocalizationsProvider);
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      if (await isWalletFolderValid(path)) {
        final walletName = path.split(p.separator).last;
        final walletsDir = await getAppWalletsDirPath();
        final network = ref.read(settingsProvider).network;

        final walletExists = await Directory(
          p.join(walletsDir, network.name, walletName),
        ).exists();
        if (walletExists) {
          ref
              .read(toastProvider.notifier)
              .showError(description: loc.wallet_already_exists);
        } else {
          final record = (path: path, walletName: walletName);
          setState(() {
            _selectedWalletFolder = record;
          });
        }
      } else {
        ref
            .read(toastProvider.notifier)
            .showError(description: loc.invalid_wallet_folder);
      }
    }
  }

  Future<void> _openImportedWallet() async {
    final password = await _getPassword();
    if (password != null) {
      if (!mounted) return;
      context.loaderOverlay.show();

      await ref
          .read(authenticationProvider.notifier)
          .openImportedWallet(
            _selectedWalletFolder!.path,
            _selectedWalletFolder!.walletName,
            password,
          );

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  Future<String?> _getPassword() async {
    return showAppDialog<String>(
      context: context,
      builder: (context, _, animation) {
        return PasswordDialog(
          animation,
          onEnter: (password) {
            context.pop(password);
          },
        );
      },
    );
  }
}
