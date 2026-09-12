import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/domain/xswd_inter_contract_permission.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_value_presentation.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

/// Presents the exact inter-contract authority attached to one transaction.
class XswdInterContractPermissionReview extends StatelessWidget {
  const XswdInterContractPermissionReview({
    required this.permission,
    required this.loc,
    super.key,
  });

  final InterContractPermission permission;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final presentation = _permissionPresentation(permission, loc);
    return Column(
      key: const ValueKey('xswd-inter-contract-permission'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTileGroup(
          label: Text(loc.xswd_inter_contract_title),
          description: Text(loc.xswd_inter_contract_transaction_scope),
          children: [
            FTile(
              prefix: const Icon(FLucideIcons.network),
              title: Text(presentation.variant),
              subtitle: Text(presentation.description),
            ),
          ],
        ),
        if (presentation.calls.isNotEmpty) ...[
          const SizedBox(height: Spaces.medium),
          FTileGroup(
            label: Text(loc.details),
            children: [
              for (final (index, call) in presentation.calls.indexed)
                _ContractRuleTile(
                  key: ValueKey('xswd-inter-contract-rule-$index'),
                  index: index,
                  call: call,
                  excluded: presentation.excluded,
                  loc: loc,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ContractRuleTile extends StatelessWidget with FTileMixin {
  const _ContractRuleTile({
    required this.index,
    required this.call,
    required this.excluded,
    required this.loc,
    super.key,
  });

  final int index;
  final ContractCall call;
  final bool excluded;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final scope = xswdContractFunctionScope(call.chunk, excluded: excluded);
    final effective = _effectiveScopeLabel(scope, loc);
    return FTile(
      prefix: const Icon(FLucideIcons.fileKey2),
      title: Text(xswdAbbreviateIdentifier(call.contract)),
      subtitle: Text(effective),
      suffix: const Icon(FLucideIcons.chevronRight),
      semanticsLabel:
          '${loc.contract} ${index + 1}, $effective, ${loc.more_details}',
      onPress: () => _showDetails(context, scope),
    );
  }

  void _showDetails(
    BuildContext context,
    XswdContractFunctionScope effectiveScope,
  ) {
    final chunks = _functionIds(call.chunk);
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => AppDialog(
        key: ValueKey('xswd-inter-contract-rule-dialog-$index'),
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Text(loc.details),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RuleDetail(
                label: loc.contract,
                child: SelectableText(
                  call.contract,
                  key: ValueKey('xswd-inter-contract-hash-$index'),
                ),
              ),
              const SizedBox(height: Spaces.medium),
              _RuleDetail(
                label: loc.xswd_inter_contract_requested_selector,
                child: SelectableText(_selectorName(call.chunk)),
              ),
              const SizedBox(height: Spaces.medium),
              _RuleDetail(
                label: loc.xswd_inter_contract_effective_scope,
                child: Text(_effectiveScopeLabel(effectiveScope, loc)),
              ),
              if (chunks.isNotEmpty) ...[
                const SizedBox(height: Spaces.medium),
                _RuleDetail(
                  label: loc.xswd_inter_contract_function_ids,
                  child: SelectableText(
                    chunks.join(', '),
                    key: ValueKey('xswd-inter-contract-functions-$index'),
                  ),
                ),
              ],
            ],
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

class _RuleDetail extends StatelessWidget {
  const _RuleDetail({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: context.bodySmall?.copyWith(
          color: context.theme.colors.mutedForeground,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: Spaces.extraSmall),
      child,
    ],
  );
}

typedef _InterContractPresentation = ({
  String variant,
  String description,
  bool excluded,
  List<ContractCall> calls,
});

_InterContractPresentation _permissionPresentation(
  InterContractPermission permission,
  AppLocalizations loc,
) => switch (permission) {
  NoInterContractPermission() => (
    variant: 'none',
    description: loc.xswd_inter_contract_none_description,
    excluded: false,
    calls: const [],
  ),
  AllInterContractPermission() => (
    variant: 'all',
    description: loc.xswd_inter_contract_effective_all,
    excluded: false,
    calls: const [],
  ),
  SpecificInterContractPermission(:final calls) => (
    variant: 'specific',
    description: calls.isEmpty
        ? loc.xswd_inter_contract_specific_empty
        : loc.xswd_inter_contract_unlisted_none,
    excluded: false,
    calls: calls,
  ),
  ExcludedInterContractPermission(:final calls) => (
    variant: 'exclude',
    description: calls.isEmpty
        ? loc.xswd_inter_contract_exclude_empty
        : loc.xswd_inter_contract_unlisted_all,
    excluded: true,
    calls: calls,
  ),
  UnknownInterContractPermission() => (
    variant: 'unknown',
    description: loc.xswd_permission_unsupported_impact,
    excluded: false,
    calls: const [],
  ),
};

String _selectorName(ContractCallChunk chunk) => switch (chunk) {
  AllContractCallChunks() => 'all',
  SpecificContractCallChunks() => 'specific',
  ExcludedContractCallChunks() => 'exclude',
  UnknownContractCallChunk() => 'unknown',
};

List<int> _functionIds(ContractCallChunk chunk) => switch (chunk) {
  SpecificContractCallChunks(:final chunks) ||
  ExcludedContractCallChunks(:final chunks) => chunks,
  AllContractCallChunks() || UnknownContractCallChunk() => const [],
};

String _effectiveScopeLabel(
  XswdContractFunctionScope scope,
  AppLocalizations loc,
) => switch (scope) {
  XswdContractFunctionScope.all => loc.xswd_inter_contract_effective_all,
  XswdContractFunctionScope.none => loc.xswd_inter_contract_effective_none,
  XswdContractFunctionScope.only => loc.xswd_inter_contract_effective_only,
  XswdContractFunctionScope.except => loc.xswd_inter_contract_effective_except,
};
