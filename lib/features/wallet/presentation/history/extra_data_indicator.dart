import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/features/wallet/presentation/components/colored_badge.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class ExtraDataIndicator extends ConsumerWidget {
  const ExtraDataIndicator({
    super.key,
    required this.extra,
    required this.onOpen,
    this.dense = false,
  });

  final XelisWalletExtraData? extra;
  final VoidCallback onOpen;
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (extra == null) {
      return Text('-', style: context.theme.typography.body.md);
    }

    final loc = ref.watch(appLocalizationsProvider);
    final parsed = ParsedExtraData.parse(loc, extra!);
    final color = flagColor(parsed.flag);
    final tooltip = [
      parsed.flag.name.capitalize(),
      parsed.label,
      ?parsed.fmtSize,
    ].join(' • ');

    return FTooltip(
      tipBuilder: (_, _) => Text(
        '${loc.view_extra_data}\n($tooltip)',
        textAlign: TextAlign.center,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          FButton.icon(
            variant: .outline,
            semanticsTooltip: loc.view_extra_data,
            onPress: onOpen,
            child: const Icon(FLucideIcons.fileText, size: 18),
          ),
          Positioned(
            right: 3,
            top: 3,
            child: Container(
              width: dense ? 8 : 9,
              height: dense ? 8 : 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.theme.colors.background,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
