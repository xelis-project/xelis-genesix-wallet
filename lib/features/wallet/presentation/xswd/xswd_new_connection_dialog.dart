import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';

import 'xswd_paste_connection_dialog.dart';
import 'xswd_qr_scanner_screen.dart';

class XswdNewConnectionDialog extends StatelessWidget {
  const XswdNewConnectionDialog(this.style, this.animation, {super.key});

  final FDialogStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return FDialog(
      style: style,
      animation: animation,
      constraints: const BoxConstraints(maxWidth: 600),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spaces.extraSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'New Connection',
                    style: theme.typography.xl2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => context.pop(),
                  child: const Icon(FIcons.x, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spaces.large),
          Row(
            children: [
              // Scan QR Button
              Expanded(
                child: _ConnectionMethodButton(
                  title: 'Scan',
                  description: 'Scan the QR code from a dApp',
                  icon: FIcons.qrCode,
                  onPressed: () async {
                    context.pop();
                    // TODO: use GoRouter
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const XswdQRScannerScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: Spaces.large),
              // Paste JSON Button
              Expanded(
                child: _ConnectionMethodButton(
                  title: 'Paste JSON',
                  description: 'Paste the connection payload from a dApp',
                  icon: FIcons.clipboard,
                  onPressed: () {
                    context.pop();
                    showFDialog<void>(
                      context: context,
                      builder: (context, style, animation) =>
                          XswdPasteConnectionDialog(style, animation),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: const [],
    );
  }
}

class _ConnectionMethodButton extends StatelessWidget {
  const _ConnectionMethodButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(Spaces.extraLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: colors.primary,
            ),
            const SizedBox(height: Spaces.large),
            Text(
              title,
              style: theme.typography.base.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spaces.small),
            Text(
              description,
              style: theme.typography.sm.copyWith(
                color: colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
