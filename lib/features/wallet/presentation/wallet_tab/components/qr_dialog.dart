import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/providers/snackbar_messenger_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class QrDialog extends ConsumerWidget {
  const QrDialog({super.key});

  void _copy(String content, String message, WidgetRef ref) {
    Clipboard.setData(ClipboardData(text: content)).then((_) {
      ref.read(snackBarMessengerProvider.notifier).showInfo(message);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final address =
        ref.watch(walletStateProvider.select((state) => state.address));

    return AlertDialog(
      scrollable: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 200,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: Spaces.small),
            InkWell(
              splashColor: Colors.transparent,
              onTap: () => _copy(address, loc.copied, ref),
              borderRadius: BorderRadius.circular(4),
              child: Text(
                address,
                style: context.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.moreColors.mutedColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Spaces.large),
            PrettyQrView.data(
              data: address,
              decoration: PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(color: context.colors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
