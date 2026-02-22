import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
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
      walletStateProvider.select((state) => state.address),
    );

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Calculate QR code size based on screen size, with constraints
    final qrSize = (screenWidth * 0.4).clamp(150.0, 250.0);
    // Ensure the dialog fits within 70% of screen height
    final maxBodyHeight = screenHeight * 0.5;

    return FDialog(
      animation: animation,
      direction: Axis.horizontal,
      title: Text(loc.receive),
      body: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxBodyHeight,
          maxWidth: screenWidth * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                loc.wallet_address_capitalize,
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: Spaces.extraSmall),
              GestureDetector(
                onTap: () => copyToClipboard(walletAddress, ref, loc.copied),
                child: Container(
                  padding: EdgeInsets.all(Spaces.small),
                  decoration: BoxDecoration(
                    color: context.theme.colors.secondaryForeground.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: context.theme.style.borderRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Spaces.small,
                    children: [
                      Flexible(
                        child: Text(
                          walletAddress,
                          style: context.theme.typography.xs.copyWith(
                            fontWeight: FontWeight.w500,
                            color: context.theme.colors.foreground,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      Icon(
                        FIcons.copy,
                        size: 14,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              Container(
                padding: EdgeInsets.all(Spaces.small),
                decoration: BoxDecoration(
                  color: context.theme.colors.background,
                  borderRadius: context.theme.style.borderRadius,
                ),
                child: SizedBox(
                  width: qrSize,
                  height: qrSize,
                  child: PrettyQrView.data(
                    data: walletAddress,
                    decoration: PrettyQrDecoration(
                      shape: PrettyQrSmoothSymbol(
                        color: context.theme.colors.foreground,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [FButton(onPress: () => context.pop(), child: Text(loc.close))],
    );
  }
}
