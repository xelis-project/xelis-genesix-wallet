import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/shared/widgets/components/hashicon_widget.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:genesix/features/authentication/application/authentication_service.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';

class WalletAddressWidget extends ConsumerWidget {
  const WalletAddressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletAddress =
        ref.watch(walletStateProvider.select((state) => state.address));

    const double iconSize = 50;
    Widget walletIcon = const SizedBox.square(dimension: iconSize);

    var address = '';
    if (walletAddress.isNotEmpty) {
      walletIcon = HashiconWidget(
        hash: walletAddress,
        size: const Size(iconSize, iconSize),
      );
      address = truncateText(walletAddress);
    }

    return Row(
      children: [
        walletIcon,
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
              onTap: () => copyToClipboard(walletAddress, ref, loc.copied),
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
