import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';

class SigningRequestEntry extends ConsumerWidget {
  const SigningRequestEntry({
    required this.controller,
    required this.maxLength,
    required this.isNodeAvailable,
    required this.nodeRequirementMessage,
    required this.isInspecting,
    required this.error,
    required this.onChanged,
    required this.onPaste,
    required this.onInspect,
    super.key,
  });

  final TextEditingController controller;
  final int maxLength;
  final bool isNodeAvailable;
  final String nodeRequirementMessage;
  final bool isInspecting;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final action = AsyncFButton(
      isLoading: isInspecting,
      onPress: isNodeAvailable && !isInspecting ? onInspect : null,
      prefix: const Icon(FLucideIcons.shieldCheck, size: 18),
      child: Text(loc.verify_multisig_signing_request),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spaces.large,
      children: [
        _EntryHeader(
          step: loc.multisig_setup_step_configuration,
          title: loc.sign_multisig_request_title,
          description: loc.multisig_signing_import_description,
        ),
        if (!isNodeAvailable)
          FAlert(
            title: Text(loc.node_required),
            subtitle: Text(nodeRequirementMessage),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FTextField(
                enabled: !isInspecting,
                control: .managed(
                  controller: controller,
                  onChange: (value) => onChanged(value.text),
                ),
                autocorrect: false,
                keyboardType: TextInputType.multiline,
                inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
                label: Text(loc.multisig_signing_request),
                hint: loc.enter_multisig_signing_request,
                error: error == null ? null : Text(error!),
                minLines: 5,
                maxLines: 5,
                clearable: (value) => value.text.isNotEmpty,
              ),
              const SizedBox(height: Spaces.small),
              Align(
                alignment: Alignment.centerRight,
                child: FButton(
                  variant: .ghost,
                  onPress: isInspecting ? null : onPaste,
                  prefix: const Icon(FLucideIcons.clipboardPaste, size: 18),
                  child: Text(loc.paste_multisig_signing_request),
                ),
              ),
            ],
          ),
        ),
        if (context.isCompactLayout)
          SizedBox(width: double.infinity, child: action)
        else
          Align(alignment: Alignment.centerRight, child: action),
      ],
    );
  }
}

class _EntryHeader extends StatelessWidget {
  const _EntryHeader({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spaces.small,
      children: [
        FBadge(variant: .outline, child: Text(step)),
        Text(title, style: context.theme.typography.display.xl2),
        Text(
          description,
          style: context.theme.typography.body.md.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
