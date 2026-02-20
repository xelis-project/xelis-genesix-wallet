import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:go_router/go_router.dart';

import 'xswd_paste_connection_dialog.dart';
import 'xswd_qr_scanner_screen.dart';

class XswdNewConnectionDialog extends ConsumerWidget {
  const XswdNewConnectionDialog(this.style, this.animation, {super.key});

  final FDialogStyle style;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final loc = ref.watch(appLocalizationsProvider);

    return FDialog(
      style: style.call,
      animation: animation,
      constraints: const BoxConstraints(maxWidth: 600),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compactLayout = width < 520;

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
                    FTooltip(
                      tipBuilder: (context, controller) => Text(loc.close),
                      child: FButton.icon(
                        style: FButtonStyle.ghost(),
                        onPress: () => context.pop(),
                        child: const Icon(FIcons.x, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: verticalGap),
              if (compactLayout) ...[
                _ConnectionMethodButton(
                  compact: true,
                  title: loc.scan_qr_code,
                  description: loc.point_camera_at_qr,
                  icon: FIcons.qrCode,
                  onPressed: () async {
                    final navigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    navigator.pop();
                    await navigator.push(
                      MaterialPageRoute<void>(
                        builder: (context) => const XswdQRScannerScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(height: verticalGap),
                _ConnectionMethodButton(
                  compact: true,
                  title: 'Paste JSON',
                  description: 'Paste dApp connection data',
                  icon: FIcons.clipboard,
                  onPressed: () {
                    final navigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    navigator.pop();
                    showAppDialog<void>(
                      context: navigator.context,
                      useRootNavigator: true,
                      builder: (ctx, style, animation) =>
                          XswdPasteConnectionDialog(
                            style,
                            animation,
                            () => Navigator.of(ctx, rootNavigator: true).pop(),
                          ),
                    );
                  },
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _ConnectionMethodButton(
                          title: loc.scan_qr_code,
                          description: loc.point_camera_at_qr,
                          icon: FIcons.qrCode,
                          onPressed: () async {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            navigator.pop();
                            await navigator.push(
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    const XswdQRScannerScreen(),
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
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            navigator.pop();
                            showAppDialog<void>(
                              context: navigator.context,
                              useRootNavigator: true,
                              builder: (ctx, style, animation) =>
                                  XswdPasteConnectionDialog(
                                    style,
                                    animation,
                                    () => Navigator.of(
                                      ctx,
                                      rootNavigator: true,
                                    ).pop(),
                                  ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
    this.compact = false,
    required this.title,
    required this.description,
    required this.icon,
    required this.onPressed,
  });

  final bool compact;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    final cappedMq = context.mediaQueryData.copyWith(
      textScaler: context.mediaQueryData.textScaler.clamp(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.2,
      ),
    );

    return MediaQuery(
      data: cappedMq,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          final padding = compact
              ? const EdgeInsets.all(14)
              : EdgeInsets.all((w * 0.08).clamp(10.0, 22.0));
          final iconSize = compact ? 56.0 : (w * 0.30).clamp(56.0, 92.0);
          final buttonHeight = compact
              ? 180.0
              : (h.isFinite && h > 0)
              ? h
              : 220.0;

          return Semantics(
            button: true,
            label: '$title. $description',
            child: SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: FButton.raw(
                style: FButtonStyle.outline(),
                onPress: onPressed,
                child: SizedBox.expand(
                  child: Padding(
                    padding: padding,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(icon, size: iconSize, color: colors.primary),
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
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
