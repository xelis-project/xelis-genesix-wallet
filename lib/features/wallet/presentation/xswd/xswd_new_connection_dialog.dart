import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/constants.dart';

import 'xswd_paste_connection_dialog.dart';
import 'xswd_qr_scanner_screen.dart';

class XswdNewConnectionDialog extends StatelessWidget {
  const XswdNewConnectionDialog(this.style, this.animation, {super.key});

  final FDialogStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return FDialog(
      style: style,
      animation: animation,
      constraints: const BoxConstraints(maxWidth: 520),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spaces.extraSmall),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'New Connection',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(context).pop(),
                  child: const Icon(FIcons.x, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spaces.small),
          const Text(
            'Choose how you want to connect:',
          ),
          const SizedBox(height: Spaces.medium),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FButton(
              style: FButtonStyle.secondary(),
              onPress: () {
                Navigator.of(context).pop();
                showFDialog<void>(
                  context: context,
                  builder: (context, style, animation) =>
                      XswdPasteConnectionDialog(style, animation),
                );
              },
              prefix: const Icon(FIcons.clipboard, size: 18),
              child: const Text('Paste'),
            ),
            const SizedBox(width: Spaces.small),
            FButton(
              style: FButtonStyle.primary(),
              onPress: () async {
                Navigator.of(context).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => XswdQRScannerScreen(),
                  ),
                );
              },
              prefix: const Icon(FIcons.qrCode, size: 18),
              child: const Text('Scan QR'),
            ),
          ],
        ),
      ],
    );
  }
}
