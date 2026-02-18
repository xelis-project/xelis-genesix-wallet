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

class XswdAppDetail extends ConsumerWidget {
  const XswdAppDetail({required this.appId, super.key});

  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final app = apps.where((a) => a.id == appId).firstOrNull;
          if (app == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.no_application_found,
                    style: context.theme.typography.lg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spaces.medium),
                  FButton(
                    style: FButtonStyle.primary(),
                    onPress: () => context.pop(),
                    child: Text(loc.ok_button),
                  ),
                ],
              ),
            );
          }
          return _buildAppDetails(context, ref, loc, app);
        },
        loading: () => const Center(child: FCircularProgress()),
        error: (error, stack) =>
            Center(child: Text('${loc.error_loading_applications}: $error')),
      ),
    );
  }

  Widget _buildAppDetails(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
    AppInfo app,
  ) {
    final muted = context.theme.colors.mutedForeground;

    return SafeArea(
      top: false,
      child: BodyLayoutBuilder(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spaces.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FCard(
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
                              onTap: () => _launchAppUrl(ref, app.url!),
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
                        style: FDividerStyle(
                          padding: const EdgeInsets.symmetric(
                            vertical: Spaces.extraSmall,
                          ),
                          color: context.theme.colors.primary,
                          width: 1,
                        ).call,
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
              ),

              const SizedBox(height: Spaces.large),

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

              if (app.permissions.isEmpty)
                FCard(
                  child: Center(
                    child: Text(
                      loc.no_data,
                      style: context.theme.typography.sm.copyWith(color: muted),
                    ),
                  ),
                )
              else
                ...(app.permissions.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key)))
                    .map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Spaces.small),
                        child: _buildPermissionChip(
                          context,
                          ref,
                          app,
                          entry.key,
                          entry.value,
                          loc,
                        ),
                      );
                    }),

              const SizedBox(height: Spaces.large),

              SizedBox(
                width: double.infinity,
                child: FButton(
                  style: FButtonStyle.destructive(),
                  onPress: () => _handleDisconnectApp(context, ref, loc, app),
                  child: const Text('Disconnect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionChip(
    BuildContext context,
    WidgetRef ref,
    AppInfo app,
    String permissionName,
    PermissionPolicy currentPolicy,
    AppLocalizations loc,
  ) {
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
            _buildPolicySelector(
              context,
              ref,
              loc,
              app,
              permissionName,
              currentPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySelector(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
    AppInfo app,
    String permissionName,
    PermissionPolicy currentPolicy,
  ) {
    return Wrap(
      spacing: Spaces.extraSmall,
      runSpacing: Spaces.extraSmall,
      children: [
        _buildPolicyButton(
          context,
          ref,
          app,
          permissionName,
          PermissionPolicy.reject,
          loc.deny,
          currentPolicy == PermissionPolicy.reject,
        ),
        _buildPolicyButton(
          context,
          ref,
          app,
          permissionName,
          PermissionPolicy.ask,
          loc.ask,
          currentPolicy == PermissionPolicy.ask,
        ),
        _buildPolicyButton(
          context,
          ref,
          app,
          permissionName,
          PermissionPolicy.accept,
          loc.allow,
          currentPolicy == PermissionPolicy.accept,
        ),
      ],
    );
  }

  Widget _buildPolicyButton(
    BuildContext context,
    WidgetRef ref,
    AppInfo app,
    String permissionName,
    PermissionPolicy policy,
    String label,
    bool isSelected,
  ) {
    final style = switch (policy) {
      PermissionPolicy.reject =>
        isSelected ? FButtonStyle.destructive() : FButtonStyle.outline(),
      PermissionPolicy.ask =>
        isSelected ? FButtonStyle.secondary() : FButtonStyle.outline(),
      PermissionPolicy.accept =>
        isSelected ? FButtonStyle.primary() : FButtonStyle.outline(),
    };

    return FButton(
      style: style,
      onPress: isSelected
          ? null
          : () => _handlePermissionChange(ref, app, permissionName, policy),
      child: Text(label),
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
    } catch (e) {
      // Error handling could show a toast here
    }
  }

  Future<void> _handleDisconnectApp(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations loc,
    AppInfo app,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) {
        return FDialog(
          style: style.call,
          animation: animation,
          constraints: const BoxConstraints(maxWidth: 560),
          title: Text(
            'Disconnect ${app.name}?',
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
                const SizedBox(height: Spaces.medium),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spaces.medium,
                    vertical: Spaces.small,
                  ),
                  decoration: BoxDecoration(
                    color: context.theme.colors.secondary.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.theme.colors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FIcons.triangleAlert,
                        size: 16,
                        color: context.theme.colors.mutedForeground,
                      ),
                      const SizedBox(height: Spaces.extraSmall),
                      Text(
                        'The app will need to reconnect to request wallet access again.',
                        textAlign: TextAlign.center,
                        style: context.theme.typography.xs.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ],
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
                    style: FButtonStyle.outline(),
                    onPress: () => dialogContext.pop(false),
                    child: Text(loc.cancel_button),
                  ),
                ),
                const SizedBox(width: Spaces.small),
                Expanded(
                  child: FButton(
                    style: FButtonStyle.destructive(),
                    onPress: () => dialogContext.pop(true),
                    child: Text(loc.confirm_button),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final walletState = ref.read(walletStateProvider);
    if (walletState.nativeWalletRepository == null) return;

    try {
      await walletState.nativeWalletRepository!.removeXswdApp(app.id);
      ref.invalidate(xswdApplicationsProvider);
      if (context.mounted) {
        context.pop();
      }
      // TODO: find a better way to refresh the app list after disconnecting because the app detail page is reloaded instantly after the app is removed, causing a brief flash of "app not found" before the list is refreshed.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.invalidate(xswdApplicationsProvider),
      );
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _launchAppUrl(WidgetRef ref, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (!uri.hasScheme)) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: '${loc.launch_url_error} $rawUrl');
      return;
    }

    if (!await launchUrl(uri)) {
      final loc = ref.read(appLocalizationsProvider);
      ref
          .read(toastProvider.notifier)
          .showError(description: '${loc.launch_url_error} $rawUrl');
    }
  }
}
