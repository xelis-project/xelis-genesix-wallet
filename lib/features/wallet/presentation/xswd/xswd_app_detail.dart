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
  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final walletOfflineMode = ref.watch(
      settingsProvider.select((settings) => settings.walletOfflineMode),
    );
    final appsAsync = ref.watch(xswdApplicationsProvider);

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
                return _XswdAppDetailContent(
                  app: liveApp,
                  loc: loc,
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

  Future<void> _handlePermissionChange(
    WidgetRef ref,
    XelisXswdApplication app,
    String permissionName,
    XelisXswdPermissionPolicy newPolicy,
  ) async {
    try {
      final updatedPermissions = Map<String, XelisXswdPermissionPolicy>.from(
        app.permissions,
      );
      updatedPermissions[permissionName] = newPolicy;

      await ref
          .read(xswdControllerProvider)
          .editXswdAppPermission(app, updatedPermissions);
    } catch (_) {
      // Keep previous behavior: fail silently for now.
    }
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
    required this.onOpenUrl,
    required this.onPermissionChange,
    required this.onDisconnect,
  });

  final XelisXswdApplication app;
  final AppLocalizations loc;
  final ValueChanged<String> onOpenUrl;
  final Future<void> Function(
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
                  onPress: onDisconnect,
                  child: Text(loc.disconnect),
                ),
              ),
              const SizedBox(height: Spaces.large),
              _XswdPermissionsSection(
                app: app,
                loc: loc,
                onPermissionChange: onPermissionChange,
              ),
            ],
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
          label: Text(app.name),
          children: [
            FTile(
              prefix: const Icon(FLucideIcons.activity),
              title: Text(loc.status),
              details: FBadge(child: Text(loc.xswd_connection_active)),
            ),
            if (url != null && url.isNotEmpty)
              FTile(
                prefix: const Icon(FLucideIcons.link),
                title: Text(url),
                subtitle: Text(loc.xswd_declared_origin),
                suffix: const Icon(FLucideIcons.externalLink),
                semanticsTooltip: loc.open_button,
                onPress: () => onOpenUrl(url),
              ),
          ],
        ),
        const SizedBox(height: Spaces.small),
        FAccordion(
          children: [
            FAccordionItem(
              title: Text(loc.xswd_application_technical_details),
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
    required this.onPermissionChange,
  });

  final XelisXswdApplication app;
  final AppLocalizations loc;
  final Future<void> Function(
    String permission,
    XelisXswdPermissionPolicy policy,
  )
  onPermissionChange;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    final sortedPermissions = app.permissions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        else
          FTileGroup(
            label: Text(loc.permissions),
            description: Text(loc.xswd_permissions_connection_scope),
            children: sortedPermissions
                .map(
                  (entry) => _XswdPermissionTile(
                    permissionName: entry.key,
                    currentPolicy: entry.value,
                    loc: loc,
                    onChange: onPermissionChange,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _XswdPermissionTile extends StatelessWidget with FTileMixin {
  const _XswdPermissionTile({
    required this.permissionName,
    required this.currentPolicy,
    required this.loc,
    required this.onChange,
  });

  final String permissionName;
  final XelisXswdPermissionPolicy currentPolicy;
  final AppLocalizations loc;
  final Future<void> Function(
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
    final effectivePolicy =
        !allowAccept && currentPolicy == XelisXswdPermissionPolicy.accept
        ? XelisXswdPermissionPolicy.ask
        : currentPolicy;
    final status = _xswdPolicyLabel(effectivePolicy, loc);
    final statusVariant = _xswdPolicyBadgeVariant(effectivePolicy);

    return FTile(
      prefix: Icon(
        supported ? FLucideIcons.shieldCheck : FLucideIcons.shieldAlert,
      ),
      title: Text(copy.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!supported) Text(loc.xswd_permission_status_unsupported),
          Text(copy.description),
          const SizedBox(height: Spaces.extraSmall),
          Text(
            permissionName,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      details: FBadge(variant: statusVariant, child: Text(status)),
      suffix: const Icon(FLucideIcons.chevronRight),
      semanticsLabel: '${copy.title}, $status',
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
              supported: supported,
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

String _xswdPolicyLabel(
  XelisXswdPermissionPolicy policy,
  AppLocalizations loc,
) => switch (policy) {
  XelisXswdPermissionPolicy.reject => loc.xswd_permission_status_blocked,
  XelisXswdPermissionPolicy.ask => loc.xswd_permission_status_ask,
  XelisXswdPermissionPolicy.accept => loc.xswd_permission_status_allowed,
};

FBadgeVariant _xswdPolicyBadgeVariant(XelisXswdPermissionPolicy policy) =>
    switch (policy) {
      XelisXswdPermissionPolicy.reject => FBadgeVariant.destructive,
      XelisXswdPermissionPolicy.ask => FBadgeVariant.outline,
      XelisXswdPermissionPolicy.accept => FBadgeVariant.primary,
    };

class _XswdPermissionEditDialog extends StatefulWidget {
  const _XswdPermissionEditDialog({
    required this.permissionName,
    required this.copy,
    required this.currentPolicy,
    required this.allowAccept,
    required this.supported,
    required this.loc,
    required this.style,
    required this.animation,
    required this.onChange,
  });

  final String permissionName;
  final XswdPermissionCopy copy;
  final XelisXswdPermissionPolicy currentPolicy;
  final bool allowAccept;
  final bool supported;
  final AppLocalizations loc;
  final FDialogStyle style;
  final Animation<double> animation;
  final Future<void> Function(
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
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.copy.description),
          const SizedBox(height: Spaces.small),
          Text(
            widget.permissionName,
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              fontFamily: 'monospace',
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
                description: Text(loc.xswd_permission_blocked_description),
              ),
              .radio(
                value: XelisXswdPermissionPolicy.ask,
                label: Text(loc.xswd_permission_status_ask),
                description: Text(
                  widget.supported
                      ? loc.xswd_permission_ask_description
                      : loc.xswd_permission_unsupported_impact,
                ),
              ),
              if (widget.allowAccept)
                .radio(
                  value: XelisXswdPermissionPolicy.accept,
                  label: Text(loc.xswd_permission_status_allowed),
                  description: Text(loc.xswd_permission_allowed_description),
                ),
            ],
          ),
        ],
      ),
      actions: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 360;
            final cancel = FButton(
              variant: .outline,
              onPress: _busy ? null : () => context.pop(),
              child: Text(loc.cancel_button),
            );
            final save = FButton(
              onPress: _busy || _selectedPolicy == widget.currentPolicy
                  ? null
                  : _save,
              prefix: _busy ? const FCircularProgress.loader() : null,
              child: Text(loc.save),
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
    setState(() => _busy = true);
    await widget.onChange(widget.permissionName, _selectedPolicy);
    if (mounted) context.pop();
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
            // const SizedBox(height: Spaces.medium),
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: Spaces.medium,
            //     vertical: Spaces.small,
            //   ),
            //   decoration: BoxDecoration(
            //     color: context.theme.colors.secondary.withValues(alpha: 0.12),
            //     borderRadius: BorderRadius.circular(8),
            //     border: Border.all(
            //       color: context.theme.colors.border.withValues(alpha: 0.6),
            //     ),
            //   ),
            //   child: Column(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Icon(
            //         FLucideIcons.triangleAlert,
            //         size: 20,
            //         color: context.theme.colors.mutedForeground,
            //       ),
            //       const SizedBox(height: Spaces.small),
            //       Text(
            //         'The app will need to reconnect to request wallet access again.',
            //         textAlign: TextAlign.center,
            //         style: context.theme.typography.body.xs.copyWith(
            //           color: context.theme.colors.mutedForeground,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
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
