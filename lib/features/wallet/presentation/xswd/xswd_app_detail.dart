import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_permission_copy.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class XswdAppDetail extends ConsumerStatefulWidget {
  const XswdAppDetail({required this.sessionReference, super.key});

  final XelisXswdSessionReference sessionReference;

  @override
  ConsumerState<XswdAppDetail> createState() => _XswdAppDetailState();
}

class _XswdAppDetailState extends ConsumerState<XswdAppDetail> {
  final _permissionFocusNodes = <String, FocusNode>{};
  String? _pendingPermissionFocusName;

  @override
  void didUpdateWidget(covariant XswdAppDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionReference != widget.sessionReference) {
      _pendingPermissionFocusName = null;
      _disposePermissionFocusNodes();
    }
  }

  @override
  void dispose() {
    _disposePermissionFocusNodes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletOfflineMode = ref.watch(
      settingsProvider.select((settings) => settings.walletOfflineMode),
    );
    final appsAsync = ref.watch(xswdApplicationsProvider);
    final recentChoices = ref
        .watch(xswdRecentChoicesProvider)
        .where((choice) => choice.sessionReference == widget.sessionReference)
        .toList(growable: false);
    final observation = ref.watch(
      xswdApplicationObservationsProvider.select(
        (observations) => observations[widget.sessionReference],
      ),
    );

    return FScaffold(
      header: FHeader.nested(
        title: Text(loc.xswd_app_details_title),
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction.back(onPress: () => context.pop()),
          ),
        ],
      ),
      child: walletOfflineMode
          ? _XswdOfflineDisabled(loc: loc)
          : appsAsync.when(
              data: (apps) {
                final liveApp = apps
                    .where(
                      (app) => app.sessionReference == widget.sessionReference,
                    )
                    .firstOrNull;
                if (liveApp == null) {
                  return _XswdAppNotFound(loc: loc);
                }
                _restorePendingPermissionFocus(liveApp);
                return _XswdAppDetailContent(
                  app: liveApp,
                  loc: loc,
                  recentChoices: recentChoices,
                  observation: observation,
                  permissionFocusNode: _permissionFocusNode,
                  onOpenUrl: (url) => _launchAppUrl(ref, url),
                  onPermissionChange: (permissionName, policy) {
                    return _handlePermissionChange(
                      ref,
                      liveApp,
                      permissionName,
                      policy,
                    );
                  },
                  onDisconnect: () =>
                      _handleDisconnectApp(context, loc, liveApp),
                );
              },
              loading: () => const Center(child: FCircularProgress()),
              error: (_, _) =>
                  Center(child: Text(loc.error_loading_applications)),
            ),
    );
  }

  FocusNode _permissionFocusNode(String permissionName) =>
      _permissionFocusNodes.putIfAbsent(
        permissionName,
        () => FocusNode(debugLabel: 'XSWD permission $permissionName'),
      );

  void _disposePermissionFocusNodes() {
    for (final node in _permissionFocusNodes.values) {
      node.dispose();
    }
    _permissionFocusNodes.clear();
  }

  Future<bool> _handlePermissionChange(
    WidgetRef ref,
    XelisXswdApplication app,
    String permissionName,
    XelisXswdPermissionPolicy newPolicy,
  ) async {
    final confirmed = await ref
        .read(xswdControllerProvider)
        .editXswdAppPermission(app, permissionName, newPolicy);
    if (confirmed && mounted) {
      _pendingPermissionFocusName = permissionName;
    }
    return confirmed;
  }

  void _restorePendingPermissionFocus(XelisXswdApplication app) {
    final permissionName = _pendingPermissionFocusName;
    if (permissionName == null ||
        !app.permissions.containsKey(permissionName)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingPermissionFocusName != permissionName) return;
      _pendingPermissionFocusName = null;
      _permissionFocusNode(permissionName).requestFocus();
    });
  }

  Future<void> _handleDisconnectApp(
    BuildContext context,
    AppLocalizations loc,
    XelisXswdApplication app,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) {
        return _DisconnectDialog(
          loc: loc,
          appName: app.name,
          style: style,
          animation: animation,
          onCancel: () => dialogContext.pop(false),
          onConfirm: () => dialogContext.pop(true),
        );
      },
    );

    if (confirmed != true) return;
    if (context.mounted) {
      context.pop(true);
    }
  }

  Future<void> _launchAppUrl(WidgetRef ref, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    final loc = ref.read(appLocalizationsProvider);

    if (uri == null || !uri.hasScheme) {
      ref
          .read(toastProvider.notifier)
          .showError(description: '${loc.launch_url_error} $rawUrl');
      return;
    }

    if (!await launchUrl(uri)) {
      ref
          .read(toastProvider.notifier)
          .showError(description: '${loc.launch_url_error} $rawUrl');
    }
  }
}

class _XswdOfflineDisabled extends StatelessWidget {
  const _XswdOfflineDisabled({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(Spaces.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FLucideIcons.cable, size: 32, color: muted),
              const SizedBox(height: Spaces.small),
              Text(
                loc.xswd_disabled_offline_title,
                textAlign: TextAlign.center,
                style: context.theme.typography.display.lg,
              ),
              const SizedBox(height: Spaces.extraSmall),
              Text(
                loc.xswd_disabled_offline_description,
                textAlign: TextAlign.center,
                style: context.theme.typography.body.sm.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XswdAppNotFound extends StatelessWidget {
  const _XswdAppNotFound({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(Spaces.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FLucideIcons.triangleAlert, size: 28, color: muted),
              const SizedBox(height: Spaces.small),
              Text(
                loc.no_application_found,
                textAlign: TextAlign.center,
                style: context.theme.typography.display.lg,
              ),
              const SizedBox(height: Spaces.extraSmall),
              Text(
                loc.xswd_app_already_disconnected,
                textAlign: TextAlign.center,
                style: context.theme.typography.body.sm.copyWith(color: muted),
              ),
              const SizedBox(height: Spaces.medium),
              SizedBox(
                width: 180,
                child: FButton(
                  variant: .outline,
                  onPress: () => context.pop(),
                  child: Text(loc.ok_button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XswdAppDetailContent extends StatelessWidget {
  const _XswdAppDetailContent({
    required this.app,
    required this.loc,
    required this.recentChoices,
    required this.observation,
    required this.permissionFocusNode,
    required this.onOpenUrl,
    required this.onPermissionChange,
    required this.onDisconnect,
  });

  final XelisXswdApplication app;
  final AppLocalizations loc;
  final List<XswdRecentChoice> recentChoices;
  final XelisXswdApplicationStateObservation? observation;
  final FocusNode Function(String permissionName) permissionFocusNode;
  final ValueChanged<String> onOpenUrl;
  final Future<bool> Function(
    String permission,
    XelisXswdPermissionPolicy policy,
  )
  onPermissionChange;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BodyLayoutBuilder(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spaces.large),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _XswdAppSummary(app: app, loc: loc, onOpenUrl: onOpenUrl),
                const SizedBox(height: Spaces.small),
                Align(
                  alignment: Alignment.centerRight,
                  child: FButton(
                    variant: .destructive,
                    mainAxisSize: MainAxisSize.min,
                    onPress: onDisconnect,
                    child: Flexible(child: Text(loc.disconnect)),
                  ),
                ),
                const SizedBox(height: Spaces.large),
                FTabs(
                  scrollable:
                      MediaQuery.sizeOf(context).width <
                          context.theme.breakpoints.sm ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3,
                  children: [
                    FTabEntry(
                      label: Text(loc.permissions),
                      child: Padding(
                        padding: const EdgeInsets.only(top: Spaces.medium),
                        child: _XswdPermissionsSection(
                          app: app,
                          loc: loc,
                          observation: observation,
                          permissionFocusNode: permissionFocusNode,
                          onPermissionChange: onPermissionChange,
                        ),
                      ),
                    ),
                    FTabEntry(
                      label: Text(loc.xswd_recent_choices_title),
                      child: Padding(
                        padding: const EdgeInsets.only(top: Spaces.medium),
                        child: _XswdRecentChoicesSection(
                          choices: recentChoices,
                          loc: loc,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XswdAppSummary extends StatelessWidget {
  const _XswdAppSummary({
    required this.app,
    required this.loc,
    required this.onOpenUrl,
  });

  final XelisXswdApplication app;
  final AppLocalizations loc;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final url = app.url?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(FLucideIcons.activity),
              title: Text(app.name),
              subtitle: url != null && url.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text(url), Text(loc.xswd_declared_origin)],
                    )
                  : null,
              details: FBadge(child: Text(loc.xswd_connection_active)),
              suffix: url != null && url.isNotEmpty
                  ? const Icon(FLucideIcons.externalLink)
                  : null,
              semanticsLabel: url != null && url.isNotEmpty
                  ? '${app.name}, ${loc.xswd_connection_active}, '
                        '${loc.xswd_declared_origin}, $url'
                  : '${app.name}, ${loc.xswd_connection_active}',
              semanticsTooltip: url != null && url.isNotEmpty
                  ? loc.open_button
                  : null,
              onPress: url != null && url.isNotEmpty
                  ? () => onOpenUrl(url)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: Spaces.small),
        FAccordion(
          children: [
            FAccordionItem(
              title: Text(loc.details),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.id,
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: Spaces.extraSmall),
                  SelectableText(
                    app.id,
                    style: context.theme.typography.body.sm.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (url != null && url.isNotEmpty) ...[
                    const SizedBox(height: Spaces.medium),
                    Text(
                      loc.xswd_declared_origin,
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    SelectableText(
                      url,
                      key: const ValueKey('xswd-app-full-origin'),
                      style: context.theme.typography.body.sm,
                    ),
                  ],
                  if (app.description.isNotEmpty) ...[
                    const SizedBox(height: Spaces.medium),
                    Text(
                      loc.description,
                      style: context.theme.typography.body.xs.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: Spaces.extraSmall),
                    Text(app.description),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _XswdPermissionsSection extends StatelessWidget {
  const _XswdPermissionsSection({
    required this.app,
    required this.loc,
    required this.observation,
    required this.permissionFocusNode,
    required this.onPermissionChange,
  });

  final XelisXswdApplication app;
  final AppLocalizations loc;
  final XelisXswdApplicationStateObservation? observation;
  final FocusNode Function(String permissionName) permissionFocusNode;
  final Future<bool> Function(
    String permission,
    XelisXswdPermissionPolicy policy,
  )
  onPermissionChange;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    final sortedPermissions = app.permissions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final allowed = <MapEntry<String, XelisXswdPermissionPolicy>>[];
    final ask = <MapEntry<String, XelisXswdPermissionPolicy>>[];
    final blocked = <MapEntry<String, XelisXswdPermissionPolicy>>[];
    final unsupported = <MapEntry<String, XelisXswdPermissionPolicy>>[];
    for (final entry in sortedPermissions) {
      final policy = tryXswdMethodPolicyForKey(entry.key);
      if (policy?.isSupported != true) {
        unsupported.add(entry);
        continue;
      }
      switch (_effectiveXswdPolicy(entry.key, entry.value)) {
        case XelisXswdPermissionPolicy.accept:
          allowed.add(entry);
        case XelisXswdPermissionPolicy.ask:
          ask.add(entry);
        case XelisXswdPermissionPolicy.reject:
          blocked.add(entry);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.xswd_permissions_connection_scope,
          style: context.theme.typography.body.sm.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.medium),
        if (observation case XelisXswdApplicationStateTimedOut()) ...[
          _XswdObservationNotice(
            key: const ValueKey('xswd-observation-warning'),
            icon: FLucideIcons.triangleAlert,
            message: loc.xswd_observation_timed_out,
          ),
          const SizedBox(height: Spaces.small),
        ],
        if (observation case XelisXswdApplicationStateFailed()) ...[
          _XswdObservationNotice(
            key: const ValueKey('xswd-observation-warning'),
            icon: FLucideIcons.triangleAlert,
            message: loc.error_loading_applications,
          ),
          const SizedBox(height: Spaces.small),
        ],
        if (sortedPermissions.isEmpty)
          AppCard(
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: Text(
                loc.no_data,
                style: context.theme.typography.body.sm.copyWith(color: muted),
              ),
            ),
          )
        else ...[
          if (allowed.isNotEmpty)
            _XswdPermissionGroup(
              key: const ValueKey('xswd-permission-group-allowed'),
              label: loc.xswd_permission_group_allowed,
              entries: allowed,
              loc: loc,
              permissionFocusNode: permissionFocusNode,
              onChange: onPermissionChange,
            ),
          if (allowed.isNotEmpty &&
              (ask.isNotEmpty || blocked.isNotEmpty || unsupported.isNotEmpty))
            const SizedBox(height: Spaces.medium),
          if (ask.isNotEmpty)
            _XswdPermissionGroup(
              key: const ValueKey('xswd-permission-group-ask'),
              label: loc.xswd_permission_group_ask,
              entries: ask,
              loc: loc,
              permissionFocusNode: permissionFocusNode,
              onChange: onPermissionChange,
            ),
          if (ask.isNotEmpty && (blocked.isNotEmpty || unsupported.isNotEmpty))
            const SizedBox(height: Spaces.medium),
          if (blocked.isNotEmpty)
            _XswdPermissionGroup(
              key: const ValueKey('xswd-permission-group-blocked'),
              label: loc.xswd_permission_group_blocked,
              entries: blocked,
              loc: loc,
              permissionFocusNode: permissionFocusNode,
              onChange: onPermissionChange,
            ),
          if (blocked.isNotEmpty && unsupported.isNotEmpty)
            const SizedBox(height: Spaces.medium),
          if (unsupported.isNotEmpty)
            _XswdPermissionGroup(
              key: const ValueKey('xswd-permission-group-unsupported'),
              label: loc.xswd_permission_group_unsupported,
              entries: unsupported,
              loc: loc,
              permissionFocusNode: permissionFocusNode,
              onChange: onPermissionChange,
            ),
        ],
      ],
    );
  }
}

class _XswdPermissionGroup extends StatelessWidget {
  const _XswdPermissionGroup({
    required this.label,
    required this.entries,
    required this.loc,
    required this.permissionFocusNode,
    required this.onChange,
    super.key,
  });

  final String label;
  final List<MapEntry<String, XelisXswdPermissionPolicy>> entries;
  final AppLocalizations loc;
  final FocusNode Function(String permissionName) permissionFocusNode;
  final Future<bool> Function(
    String permission,
    XelisXswdPermissionPolicy policy,
  )
  onChange;

  @override
  Widget build(BuildContext context) => FTileGroup(
    label: Text('$label (${entries.length})'),
    children: [
      for (final entry in entries)
        _XswdPermissionTile(
          permissionName: entry.key,
          currentPolicy: entry.value,
          loc: loc,
          focusNode: permissionFocusNode(entry.key),
          onChange: onChange,
        ),
    ],
  );
}

class _XswdObservationNotice extends StatelessWidget {
  const _XswdObservationNotice({
    required this.icon,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return FTileGroup(
      children: [FTile(prefix: Icon(icon), title: Text(message))],
    );
  }
}

class _XswdRecentChoicesSection extends StatelessWidget {
  const _XswdRecentChoicesSection({required this.choices, required this.loc});

  final List<XswdRecentChoice> choices;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.xswd_recent_choices_disclaimer,
          style: context.theme.typography.body.sm.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.medium),
        if (choices.isEmpty)
          FTileGroup(
            children: [FTile(title: Text(loc.xswd_recent_choices_empty))],
          )
        else
          FTileGroup(
            children: [
              for (final choice in choices)
                _XswdRecentChoiceTile(choice: choice, loc: loc),
            ],
          ),
      ],
    );
  }
}

class _XswdRecentChoiceTile extends StatelessWidget with FTileMixin {
  const _XswdRecentChoiceTile({required this.choice, required this.loc});

  final XswdRecentChoice choice;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final grantedMethods = choice.grantedMethods.toSet();
    final unchangedMethods = choice.methods
        .where((method) => !grantedMethods.contains(method))
        .toList(growable: false);
    final title = _xswdRecentChoiceTitle(choice, loc);
    final isPrefetch = choice.kind == XswdNoticeKind.prefetch;
    final showBatchDetails =
        isPrefetch &&
        choice.outcome != XswdChoiceOutcome.expired &&
        choice.outcome != XswdChoiceOutcome.cancelled &&
        (choice.grantedMethods.isNotEmpty || unchangedMethods.isNotEmpty);
    final ruleUnchanged =
        choice.kind == XswdNoticeKind.permission &&
        choice.scope == XswdChoiceScope.request &&
        (choice.outcome == XswdChoiceOutcome.allowed ||
            choice.outcome == XswdChoiceOutcome.refused);
    final eventDescription = choice.subscriptionEvent == null
        ? null
        : loc.xswd_recent_event(
            xswdWalletEventLabel(choice.subscriptionEvent!, loc),
          );
    final semanticsLabel = [
      title,
      ?eventDescription,
      if (ruleUnchanged) loc.xswd_recent_rule_unchanged,
    ].join(', ');

    return FTile(
      prefix: Icon(
        choice.outcome == XswdChoiceOutcome.allowed
            ? FLucideIcons.shieldCheck
            : FLucideIcons.history,
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eventDescription != null) Text(eventDescription),
          if (ruleUnchanged) Text(loc.xswd_recent_rule_unchanged),
          if (showBatchDetails)
            _XswdChoiceBatchDetails(
              grantedMethods: choice.grantedMethods,
              unchangedMethods: unchangedMethods,
              loc: loc,
            ),
        ],
      ),
      semanticsLabel: semanticsLabel,
    );
  }
}

class _XswdChoiceBatchDetails extends StatelessWidget {
  const _XswdChoiceBatchDetails({
    required this.grantedMethods,
    required this.unchangedMethods,
    required this.loc,
  });

  final List<String> grantedMethods;
  final List<String> unchangedMethods;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) => FAccordion(
    children: [
      FAccordionItem(
        title: Text(loc.more_details),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (grantedMethods.isNotEmpty)
              _XswdChoiceMethodList(
                key: const ValueKey('xswd-choice-granted-methods'),
                label: loc.xswd_recent_granted_methods,
                methods: grantedMethods,
                loc: loc,
              ),
            if (grantedMethods.isNotEmpty && unchangedMethods.isNotEmpty)
              const SizedBox(height: Spaces.small),
            if (unchangedMethods.isNotEmpty)
              _XswdChoiceMethodList(
                key: const ValueKey('xswd-choice-unchanged-methods'),
                label: loc.xswd_recent_unchanged_methods,
                methods: unchangedMethods,
                loc: loc,
              ),
          ],
        ),
      ),
    ],
  );
}

class _XswdChoiceMethodList extends StatelessWidget {
  const _XswdChoiceMethodList({
    required this.label,
    required this.methods,
    required this.loc,
    super.key,
  });

  final String label;
  final List<String> methods;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: context.theme.typography.body.sm),
      const SizedBox(height: Spaces.extraSmall),
      for (final method in methods)
        Padding(
          padding: const EdgeInsets.only(bottom: Spaces.extraSmall),
          child: Text('• ${_xswdChoiceMethodTitle(method, loc)}'),
        ),
    ],
  );
}

String _xswdChoiceMethodTitle(String method, AppLocalizations loc) =>
    xswdPermissionCopy(method, tryXswdMethodPolicyForKey(method), loc).title;

String _xswdRecentChoiceTitle(XswdRecentChoice choice, AppLocalizations loc) {
  if (choice.outcome == XswdChoiceOutcome.expired) {
    return loc.xswd_recent_request_expired;
  }
  if (choice.outcome == XswdChoiceOutcome.cancelled) {
    return loc.xswd_recent_request_cancelled;
  }

  if (choice.kind == XswdNoticeKind.application) {
    return choice.outcome == XswdChoiceOutcome.allowed
        ? loc.xswd_recent_connection_allowed
        : loc.xswd_recent_connection_refused;
  }
  if (choice.kind == XswdNoticeKind.prefetch) {
    return choice.outcome == XswdChoiceOutcome.allowed
        ? loc.xswd_recent_prefetch_allowed(choice.grantedMethods.length)
        : loc.xswd_recent_unchanged;
  }

  if (choice.methods.isEmpty) {
    return loc.permission_request;
  }
  final permission = _xswdChoiceMethodTitle(choice.methods.first, loc);
  return switch ((choice.outcome, choice.scope)) {
    (XswdChoiceOutcome.allowed, XswdChoiceScope.request) =>
      loc.xswd_recent_allowed_once(permission),
    (XswdChoiceOutcome.refused, XswdChoiceScope.request) =>
      loc.xswd_recent_refused_once(permission),
    (XswdChoiceOutcome.allowed, XswdChoiceScope.connection) =>
      loc.xswd_recent_allowed_connection(permission),
    (XswdChoiceOutcome.refused, XswdChoiceScope.connection) =>
      loc.xswd_recent_blocked_connection(permission),
    (XswdChoiceOutcome.unchanged, _) => loc.xswd_recent_unchanged,
    (XswdChoiceOutcome.expired, _) => loc.xswd_recent_request_expired,
    (XswdChoiceOutcome.cancelled, _) => loc.xswd_recent_request_cancelled,
  };
}

class _XswdPermissionTile extends StatelessWidget with FTileMixin {
  const _XswdPermissionTile({
    required this.permissionName,
    required this.currentPolicy,
    required this.loc,
    required this.focusNode,
    required this.onChange,
  });

  final String permissionName;
  final XelisXswdPermissionPolicy currentPolicy;
  final AppLocalizations loc;
  final FocusNode focusNode;
  final Future<bool> Function(
    String permission,
    XelisXswdPermissionPolicy policy,
  )
  onChange;

  @override
  Widget build(BuildContext context) {
    final policy = tryXswdMethodPolicyForKey(permissionName);
    final allowAccept = policy?.canPersist ?? false;
    final supported = policy?.isSupported ?? false;
    final copy = xswdPermissionCopy(permissionName, policy, loc);
    final effectivePolicy = _effectiveXswdPolicy(permissionName, currentPolicy);
    final status = supported
        ? _xswdPolicyLabel(effectivePolicy, loc)
        : loc.xswd_permission_group_unsupported;

    final actionLabel = xswdPermissionActionLabel(permissionName, loc);

    return FTile(
      key: ValueKey('xswd-permission-$permissionName'),
      focusNode: focusNode,
      title: ExcludeSemantics(child: Text(actionLabel)),
      suffix: const Icon(FLucideIcons.chevronRight),
      semanticsLabel: '$actionLabel, $status',
      semanticsTooltip: loc.xswd_edit_permission,
      onPress: () {
        showAppDialog<void>(
          context: context,
          builder: (dialogContext, style, animation) {
            return _XswdPermissionEditDialog(
              permissionName: permissionName,
              copy: copy,
              currentPolicy: effectivePolicy,
              allowAccept: allowAccept,
              loc: loc,
              style: style,
              animation: animation,
              onChange: onChange,
            );
          },
        );
      },
    );
  }
}

XelisXswdPermissionPolicy _effectiveXswdPolicy(
  String permissionName,
  XelisXswdPermissionPolicy currentPolicy,
) {
  final canPersist =
      tryXswdMethodPolicyForKey(permissionName)?.canPersist ?? false;
  return !canPersist && currentPolicy == XelisXswdPermissionPolicy.accept
      ? XelisXswdPermissionPolicy.ask
      : currentPolicy;
}

String _xswdPolicyLabel(
  XelisXswdPermissionPolicy policy,
  AppLocalizations loc,
) => switch (policy) {
  XelisXswdPermissionPolicy.reject => loc.xswd_permission_status_blocked,
  XelisXswdPermissionPolicy.ask => loc.xswd_permission_status_ask,
  XelisXswdPermissionPolicy.accept => loc.xswd_permission_status_allowed,
};

class _XswdPermissionEditDialog extends StatefulWidget {
  const _XswdPermissionEditDialog({
    required this.permissionName,
    required this.copy,
    required this.currentPolicy,
    required this.allowAccept,
    required this.loc,
    required this.style,
    required this.animation,
    required this.onChange,
  });

  final String permissionName;
  final XswdPermissionCopy copy;
  final XelisXswdPermissionPolicy currentPolicy;
  final bool allowAccept;
  final AppLocalizations loc;
  final FDialogStyle style;
  final Animation<double> animation;
  final Future<bool> Function(
    String permission,
    XelisXswdPermissionPolicy policy,
  )
  onChange;

  @override
  State<_XswdPermissionEditDialog> createState() =>
      _XswdPermissionEditDialogState();
}

class _XswdPermissionEditDialogState extends State<_XswdPermissionEditDialog> {
  late XelisXswdPermissionPolicy _selectedPolicy;
  bool _busy = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _selectedPolicy = widget.currentPolicy;
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    return AppDialog(
      style: widget.style,
      clipBehavior: Clip.antiAlias,
      animation: widget.animation,
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text(loc.xswd_edit_permission_title(widget.copy.title)),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.copy.description),
            const SizedBox(height: Spaces.small),
            Text(
              loc.xswd_permissions_connection_scope,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: Spaces.medium),
            FSelectGroup<XelisXswdPermissionPolicy>(
              enabled: !_busy,
              control: .managedRadio(
                initial: _selectedPolicy,
                onChange: (values) {
                  if (values.length == 1) {
                    setState(() => _selectedPolicy = values.single);
                  }
                },
              ),
              children: [
                .radio(
                  value: XelisXswdPermissionPolicy.reject,
                  label: Text(loc.xswd_permission_status_blocked),
                ),
                .radio(
                  value: XelisXswdPermissionPolicy.ask,
                  label: Text(loc.xswd_permission_status_ask),
                ),
                if (widget.allowAccept)
                  .radio(
                    value: XelisXswdPermissionPolicy.accept,
                    label: Text(loc.xswd_permission_status_allowed),
                  ),
              ],
            ),
            const SizedBox(height: Spaces.small),
            FAccordion(
              key: const ValueKey('xswd-permission-technical-details'),
              children: [
                FAccordionItem(
                  title: Text(loc.details),
                  child: SelectableText(
                    widget.permissionName,
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            if (_saveError case final error?) ...[
              const SizedBox(height: Spaces.small),
              Text(
                error,
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.destructive,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 360;
            final cancel = FButton(
              variant: .outline,
              onPress: _busy ? null : () => Navigator.of(context).pop(),
              child: Flexible(child: Text(loc.cancel_button)),
            );
            final save = FButton(
              onPress: _busy || _selectedPolicy == widget.currentPolicy
                  ? null
                  : _save,
              prefix: _busy ? const FCircularProgress.loader() : null,
              child: Flexible(child: Text(loc.save)),
            );
            return stack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cancel,
                      const SizedBox(height: Spaces.small),
                      save,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: Spaces.small),
                      Expanded(child: save),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _saveError = null;
    });
    final confirmed = await widget.onChange(
      widget.permissionName,
      _selectedPolicy,
    );
    if (!mounted) return;
    if (confirmed) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _saveError = widget.loc.xswd_permission_edit_not_confirmed;
    });
  }
}

class _DisconnectDialog extends StatelessWidget {
  const _DisconnectDialog({
    required this.loc,
    required this.appName,
    required this.style,
    required this.animation,
    required this.onCancel,
    required this.onConfirm,
  });

  final AppLocalizations loc;
  final String appName;
  final FDialogStyle style;
  final Animation<double> animation;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      style: style,
      clipBehavior: Clip.antiAlias,
      animation: animation,
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text(
        loc.disconnect_app_question(appName),
        style: context.theme.typography.display.xl,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spaces.small),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.disconnect_app_description,
              textAlign: TextAlign.center,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: FButton(
                variant: .outline,
                onPress: onCancel,
                child: Text(loc.cancel_button),
              ),
            ),
            const SizedBox(width: Spaces.small),
            Expanded(
              child: FButton(
                variant: .destructive,
                onPress: onConfirm,
                child: Text(loc.confirm_button),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
