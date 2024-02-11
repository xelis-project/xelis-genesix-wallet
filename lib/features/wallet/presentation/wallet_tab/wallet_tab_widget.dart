import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/qr_dialog.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/transfer_to_dialog.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class WalletTab extends ConsumerStatefulWidget {
  const WalletTab({super.key});

  @override
  ConsumerState<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends ConsumerState<WalletTab> {
  void _showTransferToDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const TransferToDialog(),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const QrDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletSnapshot = ref.watch(walletStateProvider);

    Widget svgAvatar = walletSnapshot.address.isNotEmpty
        ? RandomAvatar(walletSnapshot.address, height: 50, width: 50)
        : const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 32.0),
      child: ListView(
        children: [
          GridTile(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  svgAvatar,
                  const SizedBox(width: 16),
                  Text(
                    walletSnapshot.name,
                    style: context.displaySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    walletSnapshot.address.isNotEmpty
                        ? '.' * 3 +
                            walletSnapshot.address
                                .substring(walletSnapshot.address.length - 8)
                        : '...',
                    maxLines: 1,
                    style: context.bodyMedium,
                  ),
                  // TODO reduce copy button size
                  IconButton(
                      onPressed: () {
                        Clipboard.setData(
                                ClipboardData(text: walletSnapshot.address))
                            // TODO handle this with toast
                            .then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Center(child: Text("Copied!"))));
                        });
                      },
                      icon: const Icon(Icons.copy_rounded)),
                ],
              ),
            ],
          )),
          const SizedBox(height: 24),
          GridTile(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.balance,
                style: context.bodyMedium,
              ),
              const SizedBox(
                height: 8,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                walletSnapshot.xelisBalance,
                                maxLines: 1,
                                // overflow: TextOverflow.fade,
                                // softWrap: true,
                                style: context.displaySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'XEL',
                                maxLines: 1,
                                style: context.displaySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '.... USD',
                          style: context.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        IconButton.outlined(
                            onPressed: () {
                              _showTransferToDialog(context);
                            },
                            icon: const Icon(Icons.call_made_rounded)),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            loc.send,
                            maxLines: 1,
                            style: context.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        IconButton.outlined(
                            onPressed: () {
                              _showQrDialog(context);
                            },
                            icon: const Icon(Icons.call_received_rounded)),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text(
                            loc.receive,
                            maxLines: 1,
                            style: context.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )),
          const SizedBox(height: 24),
          GridTile(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.topoheight,
                style: context.bodyMedium,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                walletSnapshot.topoheight.toString(),
                style: context.displaySmall,
              ),
            ],
          )),
        ],
      ),
    );
  }
}
