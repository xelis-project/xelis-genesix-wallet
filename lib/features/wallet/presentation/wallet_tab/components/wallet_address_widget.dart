import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';

class WalletAddressWidget extends ConsumerWidget {
  const WalletAddressWidget({super.key});

  void _copy(String content, String message, WidgetRef ref) {
    Clipboard.setData(ClipboardData(text: content)).then((_) {
      ref.read(snackBarMessengerProvider.notifier).showInfo(message);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletAddress =
        ref.watch(walletStateProvider.select((state) => state.address));

    const double avatarSize = 50;
    Widget avatar = const SizedBox.square(dimension: avatarSize);

    var address = '';
    if (walletAddress.isNotEmpty) {
      avatar =
          RandomAvatar(walletAddress, height: avatarSize, width: avatarSize);
      address = truncateAddress(walletAddress);
    }

    return Row(
      children: [
        avatar,
        const SizedBox(width: Spaces.medium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.wallet_address_capitalize,
              style: context.labelLarge!
                  .copyWith(color: context.moreColors.mutedColor),
            ),
            InkWell(
              onTap: () => _copy(walletAddress, loc.copied, ref),
              borderRadius: BorderRadius.circular(4),
              child: Text(
                address,
                style: context.headlineSmall,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filled(
          icon: const Icon(
            Icons.logout,
          ),
          tooltip: loc.logout,
          onPressed: () async {
            context.loaderOverlay.show();
            await ref.read(authenticationProvider.notifier).logout();
            if (!context.mounted) return;
            context.loaderOverlay.hide();
          },
        ),
      ],
    );
  }
}
