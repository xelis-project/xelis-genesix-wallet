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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final verticalGap = (width * 0.05).clamp(12.0, Spaces.large);
          final horizontalGap = (width * 0.04).clamp(12.0, Spaces.large);

          return Column(
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
              SizedBox(height: verticalGap),
              Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _ConnectionMethodButton(
                        title: 'Scan',
                        description: 'Scan the QR code from a dApp',
                        icon: FIcons.qrCode,
                        onPressed: () async {
                          context.pop();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const XswdQRScannerScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: horizontalGap),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _ConnectionMethodButton(
                        title: 'Paste JSON',
                        description: 'Paste dApp connection data',
                        icon: FIcons.clipboard,
                        onPressed: () {
                          context.pop();
                          showFDialog<void>(
                            context: context,
                            useRootNavigator: true,
                            builder: (context, style, animation) =>
                                XswdPasteConnectionDialog(style, animation),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            ],
          );
        },
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

  final mq = MediaQuery.of(context);
  final cappedMq = mq.copyWith(
    textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
  );

  return MediaQuery(
    data: cappedMq,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Responsive padding so the icon area never gets starved in a square.
        final padding = (w * 0.08).clamp(10.0, 22.0);

        // Minimum icon area height inside the card (does NOT change text margins).
        final minIconAreaH = (w * 0.28).clamp(44.0, 72.0);

        return InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: colors.border, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon gets all leftover space, but never collapses to zero.
                Flexible(
                  fit: FlexFit.tight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minIconAreaH),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        // Give the vector a "design size" so it scales nicely.
                        child: Icon(
                          icon,
                          size: 96,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Spaces.small),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.typography.base.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: Spaces.small),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.typography.sm.copyWith(
                    color: colors.mutedForeground,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
              ],
            ),
          ),
        );
      },
    ),
  );
}
}
