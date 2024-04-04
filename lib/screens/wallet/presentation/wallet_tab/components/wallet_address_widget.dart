import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:xelis_mobile_wallet/screens/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/screens/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_content_provider.dart';
import 'package:xelis_mobile_wallet/shared/providers/snackbar_event.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class WalletAddressWidget extends ConsumerWidget {
  const WalletAddressWidget({super.key});

  void _copy(String content, String message, WidgetRef ref) {
    Clipboard.setData(ClipboardData(text: content)).then((_) {
      ref
          .read(snackbarContentProvider.notifier)
          .setContent(SnackbarEvent.info(message: message));
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletSnapshot = ref.watch(walletStateProvider);

    Widget avatar = const SizedBox.square(dimension: 50);

    var truncatedAddr = '';
    if (walletSnapshot.address.isNotEmpty) {
      avatar = RandomAvatar(walletSnapshot.address, height: 50, width: 50);
      truncatedAddr =
          '...${walletSnapshot.address.substring(walletSnapshot.address.length - 8)}';
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
            Tooltip(
              margin: const EdgeInsets.all(Spaces.medium),
              message: walletSnapshot.address,
              child: InkWell(
                onTap: () => _copy(walletSnapshot.address, loc.copied, ref),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  truncatedAddr,
                  style: context.headlineSmall,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton.filled(
          icon: const Icon(
            Icons.logout,
          ),
          tooltip: 'Logout',
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
