import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/theme/constants.dart';

class AvatarSelector extends ConsumerWidget {
  const AvatarSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address =
        ref.watch(walletStateProvider.select((value) => value.address));
    final svgAvatar = address.isNotEmpty
        ? RandomAvatar(address, height: 100, width: 100)
        : const SizedBox.shrink();
    return Center(
      child: Column(
        children: [
          Text(
            'My Wallet Avatar',
            style: context.titleMedium,
          ),
          const SizedBox(height: Spaces.medium),
          Tooltip(
            message:
                'This avatar is generated based on your unique wallet address',
            child: svgAvatar,
          ),
          const SizedBox(height: Spaces.medium),
        ],
      ),
    );
  }
}
