import 'package:material_ui/material_ui.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';

/// Untrusted review prose is laid out in full only after an explicit action.
class XswdReviewText extends StatelessWidget {
  const XswdReviewText({
    required this.label,
    required this.value,
    required this.loc,
    super.key,
  });

  static const previewCharacters = 256;
  final String label;
  final String value;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final truncated = value.length > previewCharacters;
    var end = previewCharacters;
    if (truncated) {
      final lastUnit = value.codeUnitAt(end - 1);
      if (lastUnit >= 0xd800 && lastUnit <= 0xdbff) end--;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.bodyMedium?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(
          truncated ? '${value.substring(0, end)}…' : value,
          key: const ValueKey('xswd-review-text-preview'),
          style: context.bodyLarge,
        ),
        if (truncated) ...[
          const SizedBox(height: Spaces.small),
          FButton(
            key: const ValueKey('xswd-review-text-reveal'),
            onPress: () => _reveal(context),
            child: Text(loc.more_details),
          ),
        ],
      ],
    );
  }

  void _reveal(BuildContext context) {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => AppDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Text(label),
        body: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.5,
          child: XswdFullValueView(
            value: value,
            key: const ValueKey('xswd-review-text-full'),
            chunkKeyPrefix: 'xswd-review-text-full',
            monospace: false,
          ),
        ),
        actions: [
          FButton(
            onPress: () => Navigator.of(context).pop(),
            child: Text(loc.close),
          ),
        ],
      ),
    );
  }
}
