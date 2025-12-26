import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:go_router/go_router.dart';

class XswdAppDetail extends ConsumerWidget {
  const XswdAppDetail({required this.appId, super.key});

  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    final appsAsync = ref.watch(xswdApplicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Details'),
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: appsAsync.when(
        data: (apps) {
          final app = apps.where((a) => a.id == appId).firstOrNull;
          if (app == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'App not found',
                    style: context.headlineSmall,
                  ),
                  const SizedBox(height: Spaces.medium),
                  FButton(
                    style: FButtonStyle.primary(),
                    onPress: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          return _buildAppDetails(context, ref, loc, app);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildAppDetails(
    BuildContext context,
    WidgetRef ref,
    dynamic loc,
    AppInfo app,
  ) {
    final muted = context.theme.colors.mutedForeground;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spaces.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Spaces.large),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.theme.colors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: context.headlineMedium,
                ),
                if (app.url != null && app.url!.isNotEmpty) ...[
                  const SizedBox(height: Spaces.small),
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: muted),
                      const SizedBox(width: Spaces.extraSmall),
                      Expanded(
                        child: Text(
                          app.url!,
                          style: context.bodyMedium?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: Spaces.medium),
                Text(
                  'App ID',
                  style: context.bodySmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                SelectableText(
                  app.id,
                  style: context.bodyMedium?.copyWith(
                    fontFamily: 'monospace'
                  ),
                ),
                if (app.description.isNotEmpty) ...[
                  const SizedBox(height: Spaces.small),
                  FDivider(
                    style: FDividerStyle(
                      padding: const EdgeInsets.symmetric(vertical: Spaces.extraSmall),
                      color: FTheme.of(context).colors.primary,
                      width: 1,
                    ),
                  ),
                  const SizedBox(height: Spaces.small),
                  Text(
                    'Description',
                    style: context.bodySmall?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: Spaces.extraSmall),
                  Text(
                    app.description,
                    style: context.bodyMedium,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: Spaces.large),

          // Permissions Section
          Row(
            children: [
              Expanded(
                child: Text(
                  'Permissions',
                  style: context.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spaces.medium),

          if (app.permissions.isEmpty)
            Container(
              padding: const EdgeInsets.all(Spaces.large),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.theme.colors.border,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  'No permissions configured',
                  style: context.bodyMedium?.copyWith(color: muted),
                ),
              ),
            )
          else
            ...(app.permissions.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
              .map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spaces.small),
                  child: _buildPermissionCard(
                    context,
                    ref,
                    loc,
                    app,
                    entry.key,
                    entry.value,
                  ),
                );
              }),

          const SizedBox(height: Spaces.large),

          // Disconnect Button
          SizedBox(
            width: double.infinity,
            child: FButton(
              style: FButtonStyle.destructive(),
              onPress: () => _handleDisconnectApp(context, ref, loc, app),
              child: const Text('Disconnect App'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    WidgetRef ref,
    dynamic loc,
    AppInfo app,
    String permissionName,
    PermissionPolicy currentPolicy,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spaces.medium,
        vertical: Spaces.medium,
      ),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
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
                    style: context.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spaces.medium),
          _buildPolicySelector(
            context,
            ref,
            app,
            permissionName,
            currentPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySelector(
    BuildContext context,
    WidgetRef ref,
    AppInfo app,
    String permissionName,
    PermissionPolicy currentPolicy,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: context.theme.colors.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPolicyOption(
            context,
            ref,
            app,
            permissionName,
            PermissionPolicy.reject,
            'Deny',
            currentPolicy == PermissionPolicy.reject,
            isFirst: true,
          ),
          _buildPolicyOption(
            context,
            ref,
            app,
            permissionName,
            PermissionPolicy.ask,
            'Ask',
            currentPolicy == PermissionPolicy.ask,
          ),
          _buildPolicyOption(
            context,
            ref,
            app,
            permissionName,
            PermissionPolicy.accept,
            'Allow',
            currentPolicy == PermissionPolicy.accept,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyOption(
    BuildContext context,
    WidgetRef ref,
    AppInfo app,
    String permissionName,
    PermissionPolicy policy,
    String label,
    bool isSelected, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    if (isSelected) {
      switch (policy) {
        case PermissionPolicy.ask:
          backgroundColor = context.theme.colors.mutedForeground.withValues(alpha: 0.2);
          textColor = context.theme.colors.foreground;
        case PermissionPolicy.accept:
          backgroundColor = context.theme.colors.primary;
          textColor = context.theme.colors.primaryForeground;
        case PermissionPolicy.reject:
          backgroundColor = context.theme.colors.destructive;
          textColor = context.theme.colors.destructiveForeground;
      }
      borderColor = null;
    } else {
      backgroundColor = Colors.transparent;
      textColor = context.theme.colors.mutedForeground;
      borderColor = context.theme.colors.border;
    }

    return InkWell(
      onTap: isSelected
          ? null
          : () => _handlePermissionChange(ref, app, permissionName, policy),
      borderRadius: BorderRadius.horizontal(
        left: isFirst ? const Radius.circular(5) : Radius.zero,
        right: isLast ? const Radius.circular(5) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spaces.medium,
          vertical: Spaces.small,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: !isFirst && !isSelected
              ? Border(
                  left: BorderSide(
                    color: borderColor ?? context.theme.colors.border,
                    width: 1,
                  ),
                )
              : null,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(5) : Radius.zero,
            right: isLast ? const Radius.circular(5) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: context.bodySmall?.copyWith(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
    } catch (e) {
      // Error handling could show a toast here
    }
  }

  Future<void> _handleDisconnectApp(
    BuildContext context,
    WidgetRef ref,
    dynamic loc,
    AppInfo app,
  ) async {
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) {
        return FDialog(
          style: style,
          animation: animation,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Disconnect ${app.name}?',
                style: context.headlineSmall,
              ),
              const SizedBox(height: Spaces.medium),
              Text(
                'This will revoke all permissions and close the connection. The app will need to reconnect to access your wallet again.',
                style: context.bodyMedium,
              ),
            ],
          ),
          actions: [
            FButton(
              style: FButtonStyle.ghost(),
              onPress: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancel_button),
            ),
            FButton(
              style: FButtonStyle.destructive(),
              onPress: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Disconnect'),
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
    } catch (e) {
      // Error handling
    }
  }
}
