import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_commands_provider.dart';
import 'package:genesix/features/authentication/domain/wallet_session_command_result.dart';
import 'package:genesix/features/router/route_utils.dart';
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
    ref.listen(settingsProvider.select((state) => state.network), (
      previous,
      next,
    ) {
      if (previous != next && _selectedWalletFolder != null) {
        setState(() {
          _selectedWalletFolder = null;
        });
      }
    });

    bool showOpenButton =
        _selectedWalletFolder != null && _selectedWalletFolder!.path.isNotEmpty;

    return FCard(
      subtitle: Text(loc.restore_wallet_from_folder),
      child: Column(
        children: [
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
    final network = ref.read(settingsProvider).network;
    final result = await _pickRestorableWalletFolder(network.name);
    if (!mounted) return;

    switch (result) {
      case _RestoreFolderCancelled():
        return;
      case _RestoreFolderInvalid():
        ref
            .read(toastProvider.notifier)
            .showError(description: loc.invalid_wallet_folder);
      case _RestoreFolderAlreadyExists():
        ref
            .read(toastProvider.notifier)
            .showError(description: loc.wallet_already_exists);
      case _RestoreFolderSelected(:final path, :final walletName):
        setState(() {
          _selectedWalletFolder = (path: path, walletName: walletName);
        });
    }
  }

  Future<_RestoreFolderSelectionResult> _pickRestorableWalletFolder(
    String networkName,
  ) async {
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return const _RestoreFolderCancelled();

    if (!await isWalletFolderValid(path)) {
      return const _RestoreFolderInvalid();
    }

    final walletName = path.split(p.separator).last;
    final walletsDir = await getAppWalletsDirPath();
    final walletExists = await Directory(
      p.join(walletsDir, networkName, walletName),
    ).exists();

    if (walletExists) return const _RestoreFolderAlreadyExists();
    return _RestoreFolderSelected(path: path, walletName: walletName);
  }

  Future<void> _openImportedWallet() async {
    final password = await _getPassword();
    if (password != null) {
      if (!mounted) return;
      context.loaderOverlay.show();

      final result = await ref
          .read(walletSessionCommandsProvider.notifier)
          .openImportedWallet(
            _selectedWalletFolder!.path,
            _selectedWalletFolder!.walletName,
            password,
          );

      if (result is WalletSessionCommandSuccess && mounted) {
        context.go(AuthAppScreen.home.toPath, extra: result.seedToReveal);
      }

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

sealed class _RestoreFolderSelectionResult {
  const _RestoreFolderSelectionResult();
}

class _RestoreFolderCancelled extends _RestoreFolderSelectionResult {
  const _RestoreFolderCancelled();
}

class _RestoreFolderInvalid extends _RestoreFolderSelectionResult {
  const _RestoreFolderInvalid();
}

class _RestoreFolderAlreadyExists extends _RestoreFolderSelectionResult {
  const _RestoreFolderAlreadyExists();
}

class _RestoreFolderSelected extends _RestoreFolderSelectionResult {
  const _RestoreFolderSelected({required this.path, required this.walletName});

  final String path;
  final String walletName;
}
