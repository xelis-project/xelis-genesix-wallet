import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_app_detail.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

import 'xswd_new_connection_dialog.dart';
import 'xswd_qr_scanner_screen.dart';

class XSWDContent extends ConsumerStatefulWidget {
  const XSWDContent({super.key});

  @override
  ConsumerState createState() => _XSWDContentState();
}

class _XSWDContentState extends ConsumerState<XSWDContent> {
  final _scrollController = ScrollController();
  Timer? _statusCheckTimer;
  bool _isXswdRunning = false;

  // bool get _showFooter {
  //   if (kIsWeb) return true;
  //   return Platform.isAndroid || Platform.isIOS;
  // }

  @override
  void initState() {
    super.initState();

    // Only check server status on desktop platforms
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isMobile) {
      _checkXswdStatus();

      // Check XSWD status periodically
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _checkXswdStatus();
      });
    }
  }

  Future<void> _checkXswdStatus() async {
    final walletState = ref.read(walletStateProvider);
    if (walletState.nativeWalletRepository != null) {
      try {
        final isRunning = await walletState.nativeWalletRepository!
            .isXswdRunning();
        if (mounted) {
          setState(() {
            _isXswdRunning = isRunning;
          });
        }
      } catch (e) {
        // Silently fail - server might not be available
      }
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final appsAsync = ref.watch(xswdApplicationsProvider);

    return Column(
      children: [
        Expanded(
          child: appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return _buildEmptyState(context, loc);
              }
              return _buildAppsList(context, loc, apps);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error loading XSWD apps: $error')),
          ),
        ),
        // Footer with "New Connection" button
        _buildFooter(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link,
            size: 64,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(height: Spaces.large),
          Text(
            'No Connected Apps',
            style: context.headlineSmall?.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.medium),
          _buildServerStatus(context, loc),
        ],
      ),
    );
  }

  Widget _buildAppsList(
    BuildContext context,
    AppLocalizations loc,
    List<AppInfo> apps,
  ) {
    return FadedScroll(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(Spaces.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Connected Apps', style: context.headlineMedium),
                ),
                _buildServerStatus(context, loc),
              ],
            ),
            const SizedBox(height: Spaces.large),
            ...apps.map(
              (app) => Padding(
                padding: const EdgeInsets.only(bottom: Spaces.medium),
                child: _buildAppCard(context, loc, app),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(
    BuildContext context,
    AppLocalizations loc,
    AppInfo app,
  ) {
    final muted = context.theme.colors.mutedForeground;
    final permissionCount = app.permissions.length;

    return InkWell(
      onTap: () {
        // TODO: use GoRouter
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => XswdAppDetail(appId: app.id)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.theme.colors.border, width: 1),
        ),
        padding: const EdgeInsets.all(Spaces.large),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(app.name, style: context.headlineSmall),
                  if (app.url != null && app.url!.isNotEmpty) ...[
                    const SizedBox(height: Spaces.extraSmall),
                    Text(
                      app.url!,
                      style: context.bodySmall?.copyWith(color: muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: Spaces.small),
                  Row(
                    children: [
                      Icon(Icons.verified_user, size: 16, color: muted),
                      const SizedBox(width: Spaces.extraSmall),
                      Text(
                        permissionCount == 1
                            ? '1 permission'
                            : '$permissionCount permissions',
                        style: context.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatus(BuildContext context, AppLocalizations loc) {
    // Mobile and Web use relay mode only - show relay status instead of server status
    final isRelay =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    final statusText = isRelay
        ? 'Relay Mode'
        : (_isXswdRunning
              ? '${loc.xswd_status}: ${loc.running.capitalize()}'
              : '${loc.xswd_status}: ${loc.stopped.capitalize()}');

    final statusColor = isRelay || _isXswdRunning
        ? context.theme.colors.primary
        : context.theme.colors.destructive;

    final bgColor = isRelay || _isXswdRunning
        ? context.theme.colors.primaryForeground.withValues(alpha: 0.1)
        : context.theme.colors.destructiveForeground.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spaces.medium,
        vertical: Spaces.small,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spaces.small),
          Text(
            statusText,
            style: context.bodyMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.theme.colors.border, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(Spaces.large),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              showAppDialog<void>(
                context: context,
                builder: (context, style, animation) =>
                    XswdNewConnectionDialog(style, animation),
              );
              return;
            },
            icon: const Icon(Icons.qr_code_scanner, size: 20),
            label: const Text('New Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.colors.primary,
              foregroundColor: context.theme.colors.primaryForeground,
              padding: const EdgeInsets.symmetric(
                vertical: Spaces.medium,
                horizontal: Spaces.large,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
