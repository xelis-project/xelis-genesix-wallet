import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class QrDialog extends ConsumerWidget {
  const QrDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final address =
        ref.watch(walletStateProvider.select((state) => state.address));

    return GenericDialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: Spaces.small),
            InkWell(
              splashColor: Colors.transparent,
              onTap: () => copyToClipboard(address, ref, loc.copied),
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
