import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/domain/parsed_extra_data.dart';
import 'package:genesix/features/wallet/presentation/components/colored_badge.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class ExtraDataIndicator extends StatelessWidget {
  const ExtraDataIndicator({
    super.key,
    required this.extra,
    required this.onOpen,
    this.dense = false,
  });

  final ExtraData? extra;
  final VoidCallback onOpen;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (extra == null) {
      return Text('-', style: context.theme.typography.base);
    }

    final loc = AppLocalizations.of(context);
    final parsed = ParsedExtraData.parse(loc, extra!);
    final color = flagColor(parsed.flag);
    final tooltip =
        '${parsed.flag.name.capitalize()} • ${parsed.label} • ${parsed.fmtSize}';

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
            onPress: onOpen,
            child: const Icon(FIcons.fileText, size: 18),
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
