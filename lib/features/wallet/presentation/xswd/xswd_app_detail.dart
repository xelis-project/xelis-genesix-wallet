import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/widgets/components/body_layout_builder.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class XswdAppDetail extends ConsumerStatefulWidget {
  const XswdAppDetail({required this.appId, super.key});

  final String appId;

  @override
  ConsumerState<XswdAppDetail> createState() => _XswdAppDetailState();
}

class _XswdAppDetailState extends ConsumerState<XswdAppDetail> {
  bool _isClosing = false;
  AppInfo? _cachedApp;

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final appsAsync = ref.watch(xswdApplicationsProvider);

    return FScaffold(
      header: FHeader.nested(
        title: Text('${loc.applications} ${loc.details}'),
        prefixes: [
          Padding(
            padding: const EdgeInsets.all(Spaces.small),
            child: FHeaderAction.back(onPress: () => context.pop()),
          ),
        ],
      ),
      child: appsAsync.when(
        data: (apps) {
          final liveApp = apps.where((a) => a.id == widget.appId).firstOrNull;
          if (liveApp != null) {
            _cachedApp = liveApp;
          }
          final app = liveApp ?? _cachedApp;

          if (app == null) {
            if (_isClosing) {
              return const Center(child: FCircularProgress());
            }
            return _XswdAppNotFound(loc: loc);
          }
          return _XswdAppDetailContent(
            app: app,
            loc: loc,
            onOpenUrl: (url) => _launchAppUrl(ref, url),
            onPermissionChange: (permissionName, policy) {
              return _handlePermissionChange(ref, app, permissionName, policy);
            },
            onDisconnect: () => _handleDisconnectApp(context, loc, app),
          );
        },
        loading: () => const Center(child: FCircularProgress()),
        error: (error, stack) =>
            Center(child: Text('${loc.error_loading_applications}: $error')),
      ),
    );
  }

  Future<void> _handlePermissionChange(
    WidgetRef ref,
    AppInfo app,
    String permissionName,
    PermissionPolicy newPolicy,
  ) async {
    final walletState = ref.read(walletStateProvider);
    if (walletState.nativeWalletRepository == null) return;

    try {
      final updatedPermissions = Map<String, PermissionPolicy>.from(
        app.permissions,
      );
      updatedPermissions[permissionName] = newPolicy;

      await walletState.nativeWalletRepository!.modifyXSWDAppPermissions(
        app.id,
        updatedPermissions,
      );

      ref.invalidate(xswdApplicationsProvider);
    } catch (_) {
      // Keep previous behavior: fail silently for now.
    }
  }

  Future<void> _handleDisconnectApp(
    BuildContext context,
    AppLocalizations loc,
    AppInfo app,
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
      setState(() {
        _isClosing = true;
        _cachedApp = app;
      });
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
              Icon(FIcons.triangleAlert, size: 28, color: muted),
              const SizedBox(height: Spaces.small),
              Text(
                loc.no_application_found,
                textAlign: TextAlign.center,
                style: context.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spaces.extraSmall),
              Text(
                'This app may already be disconnected.',
                textAlign: TextAlign.center,
                style: context.theme.typography.sm.copyWith(color: muted),
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

  final AppInfo app;
  final AppLocalizations loc;
  final ValueChanged<String> onOpenUrl;
  final Future<void> Function(String permission, PermissionPolicy policy)
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
              _XswdAppInfoCard(app: app, loc: loc, onOpenUrl: onOpenUrl),
              const SizedBox(height: Spaces.large),
              _XswdPermissionsSection(
                app: app,
                loc: loc,
                onPermissionChange: onPermissionChange,
              ),
              const SizedBox(height: Spaces.large),
              SizedBox(
                width: double.infinity,
                child: FButton(
                  variant: .destructive,
                  onPress: onDisconnect,
                  child: const Text('Disconnect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XswdAppInfoCard extends StatelessWidget {
  const _XswdAppInfoCard({
    required this.app,
    required this.loc,
    required this.onOpenUrl,
  });

  final AppInfo app;
  final AppLocalizations loc;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;

    return FCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.name,
            style: context.theme.typography.xl.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (app.url != null && app.url!.isNotEmpty) ...[
            const SizedBox(height: Spaces.small),
            Row(
              children: [
                Icon(FIcons.link, size: 16, color: muted),
                const SizedBox(width: Spaces.extraSmall),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOpenUrl(app.url!),
                    child: Text(
                      app.url!,
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: context.theme.colors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Spaces.medium),
          Text(
            '${loc.applications} ${loc.id}',
            style: context.theme.typography.xs.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            app.id,
            style: context.theme.typography.sm.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          if (app.description.isNotEmpty) ...[
            const SizedBox(height: Spaces.small),
            FDivider(
              style: .delta(
                padding: .value(.symmetric(vertical: Spaces.extraSmall)),
                color: context.theme.colors.primary,
                width: 1,
              ),
            ),
            const SizedBox(height: Spaces.small),
            Text(
              loc.description,
              style: context.theme.typography.xs.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Spaces.extraSmall),
            Text(app.description, style: context.theme.typography.sm),
          ],
        ],
      ),
    );
  }
}

class _XswdPermissionsSection extends StatelessWidget {
  const _XswdPermissionsSection({
    required this.app,
    required this.loc,
    required this.onPermissionChange,
  });

  final AppInfo app;
  final AppLocalizations loc;
  final Future<void> Function(String permission, PermissionPolicy policy)
  onPermissionChange;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    final sortedPermissions = app.permissions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                loc.permissions,
                style: context.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spaces.medium),
        if (sortedPermissions.isEmpty)
          FCard(
            child: Center(
              child: Text(
                loc.no_data,
                style: context.theme.typography.sm.copyWith(color: muted),
              ),
            ),
          )
        else
          ...sortedPermissions.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: Spaces.small),
              child: _XswdPermissionCard(
                permissionName: entry.key,
                currentPolicy: entry.value,
                loc: loc,
                onChange: onPermissionChange,
              ),
            ),
          ),
      ],
    );
  }
}

class _XswdPermissionCard extends StatelessWidget {
  const _XswdPermissionCard({
    required this.permissionName,
    required this.currentPolicy,
    required this.loc,
    required this.onChange,
  });

  final String permissionName;
  final PermissionPolicy currentPolicy;
  final AppLocalizations loc;
  final Future<void> Function(String permission, PermissionPolicy policy)
  onChange;

  @override
  Widget build(BuildContext context) {
    return FCard.raw(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Spaces.small),
        decoration: BoxDecoration(
          border: Border.all(
            color: context.theme.colors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.code,
              size: 16,
              color: context.theme.colors.mutedForeground,
            ),
            const SizedBox(width: Spaces.small),
            Expanded(
              child: Text(
                permissionName,
                style: context.theme.typography.sm.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: Spaces.small),
            _XswdPolicySelector(
              loc: loc,
              currentPolicy: currentPolicy,
              onChange: (policy) => onChange(permissionName, policy),
            ),
          ],
        ),
      ),
    );
  }
}

class _XswdPolicySelector extends StatelessWidget {
  const _XswdPolicySelector({
    required this.loc,
    required this.currentPolicy,
    required this.onChange,
  });

  final AppLocalizations loc;
  final PermissionPolicy currentPolicy;
  final ValueChanged<PermissionPolicy> onChange;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spaces.extraSmall,
      runSpacing: Spaces.extraSmall,
      children: [
        _XswdPolicyButton(
          policy: PermissionPolicy.reject,
          currentPolicy: currentPolicy,
          label: loc.deny,
          onPress: onChange,
        ),
        _XswdPolicyButton(
          policy: PermissionPolicy.ask,
          currentPolicy: currentPolicy,
          label: loc.ask,
          onPress: onChange,
        ),
        _XswdPolicyButton(
          policy: PermissionPolicy.accept,
          currentPolicy: currentPolicy,
          label: loc.allow,
          onPress: onChange,
        ),
      ],
    );
  }
}

class _XswdPolicyButton extends StatelessWidget {
  const _XswdPolicyButton({
    required this.policy,
    required this.currentPolicy,
    required this.label,
    required this.onPress,
  });

  final PermissionPolicy policy;
  final PermissionPolicy currentPolicy;
  final String label;
  final ValueChanged<PermissionPolicy> onPress;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentPolicy == policy;
    final styleVariant = switch (policy) {
      PermissionPolicy.reject =>
        isSelected ? FButtonVariant.destructive : FButtonVariant.outline,
      PermissionPolicy.ask =>
        isSelected ? FButtonVariant.secondary : FButtonVariant.outline,
      PermissionPolicy.accept => isSelected ? null : FButtonVariant.outline,
    };

    return FButton(
      variant: styleVariant,
      onPress: isSelected ? null : () => onPress(policy),
      child: Text(label),
    );
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
    return FDialog(
      animation: animation,
      constraints: const BoxConstraints(maxWidth: 560),
      title: Text(
        'Disconnect $appName?',
        style: context.theme.typography.xl.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spaces.small),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This will revoke all permissions and close this application connection.',
              textAlign: TextAlign.center,
              style: context.theme.typography.sm.copyWith(
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
            //         FIcons.triangleAlert,
            //         size: 20,
            //         color: context.theme.colors.mutedForeground,
            //       ),
            //       const SizedBox(height: Spaces.small),
            //       Text(
            //         'The app will need to reconnect to request wallet access again.',
            //         textAlign: TextAlign.center,
            //         style: context.theme.typography.xs.copyWith(
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
