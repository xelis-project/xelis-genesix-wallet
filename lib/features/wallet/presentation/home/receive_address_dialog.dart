import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/domain/network_translate_name.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class ReceiveAddressDialog extends ConsumerWidget {
  const ReceiveAddressDialog(this.animation, {super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletAddress = ref.watch(
      walletRuntimeProvider.select((state) => state.address),
    );
    final network = ref.watch(
      walletRuntimeProvider.select((state) => state.network),
    );

    final isWideScreen = context.isWideScreen;
    final maxDialogWidth = context.responsiveDialogMaxWidth(medium: 600);
    final maxBodyHeight = context.responsiveDialogMaxHeight();
    final dialogWidth = context.responsiveDialogWidth(medium: 600);
    final qrSize = math
        .min(dialogWidth - (Spaces.medium * 4), maxBodyHeight * 0.5)
        .clamp(168.0, 280.0)
        .toDouble();
    final isDarkTheme =
        context.theme.colors.background.computeLuminance() < 0.5;
    final qrForegroundColor = isDarkTheme
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111111);

    return FDialog(
      clipBehavior: Clip.antiAlias,
      animation: animation,
      constraints: BoxConstraints(minWidth: 280, maxWidth: maxDialogWidth),
      body: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxBodyHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(Spaces.extraSmall),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        loc.receive,
                        style: context.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ),
                    FButton.icon(
                      variant: .ghost,
                      onPress: () => context.pop(),
                      child: const Icon(FLucideIcons.x, size: 22),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spaces.extraSmall),
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.theme.colors.secondaryForeground.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: context.theme.style.borderRadius.md,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spaces.small,
                      vertical: Spaces.extraSmall,
                    ),
                    child: Text(
                      translateNetworkName(loc, network),
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.theme.colors.secondaryForeground.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: context.theme.style.borderRadius.md,
                  border: Border.all(color: context.theme.colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Spaces.small),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Spaces.small,
                    children: [
                      Text(
                        loc.wallet_address_capitalize,
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      SelectableText(
                        walletAddress,
                        maxLines: isWideScreen ? 1 : null,
                        style: context.theme.typography.body.xs.copyWith(
                          color: context.theme.colors.foreground,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FButton(
                          variant: .outline,
                          prefix: const Icon(FLucideIcons.copy, size: 16),
                          onPress: walletAddress.isEmpty
                              ? null
                              : () => copyToClipboard(
                                  walletAddress,
                                  ref,
                                  loc.copied_to_clipboard,
                                ),
                          child: Text(loc.copy),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              Padding(
                padding: const EdgeInsets.all(Spaces.small),
                child: Center(
                  child: SizedBox(
                    width: qrSize,
                    height: qrSize,
                    child: PrettyQrView.data(
                      data: walletAddress,
                      decoration: PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(color: qrForegroundColor),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: const [],
    );
  }
}
