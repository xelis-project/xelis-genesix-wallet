import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';

import 'xswd_new_connection_dialog.dart';

class XSWDContent extends ConsumerStatefulWidget {
  const XSWDContent({super.key});

  @override
  ConsumerState createState() => _XSWDContentState();
}

class _XSWDContentState extends ConsumerState<XSWDContent> {
  final _scrollController = ScrollController();
  Timer? _statusCheckTimer;
  bool _isXswdRunning = false;

  @override
  void initState() {
    super.initState();

    // Only check server status on desktop platforms
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (!isMobile) {
      _checkXswdStatus();
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
      } catch (_) {
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
    final enableXswd = ref.watch(
      settingsProvider.select((settings) => settings.enableXswd),
    );
    final appsAsync = ref.watch(xswdApplicationsProvider);

    final stateBody = enableXswd
        ? appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return _buildStatePanel(
                  key: const ValueKey<String>('xswd-enabled-empty'),
                  icon: FIcons.link,
                  title: loc.no_application_connected,
                  description: 'Use New Connection to add a trusted app.',
                  trailing: _buildConnectionStatusBadge(
                    context,
                    loc,
                    enableXswd: true,
                  ),
                );
              }
              return _buildAppsList(context, apps);
            },
            loading: () => Center(
              key: const ValueKey<String>('xswd-loading'),
              child: FCircularProgress(),
            ),
            error: (error, stack) => Center(
              key: const ValueKey<String>('xswd-error'),
              child: Text('Error loading connected apps: $error'),
            ),
          )
        : _buildStatePanel(
            key: const ValueKey<String>('xswd-disabled'),
            icon: FIcons.cable,
            title: 'Connected Apps is off',
            description: 'Turn it on to approve requests from trusted apps.',
            trailing: _buildConnectionStatusBadge(
              context,
              loc,
              enableXswd: false,
            ),
          );

    return Column(
      children: [
        Expanded(
          child: FadedScroll(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(Spaces.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModeCard(context, enableXswd),
                  const SizedBox(height: Spaces.large),
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: AppDurations.animFast,
                    ),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: stateBody,
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(context, enableXswd),
      ],
    );
  }

  Widget _buildModeCard(BuildContext context, bool enableXswd) {
    final subtitle = enableXswd
        ? 'Manage connected apps and their permissions.'
        : 'Turn this on to connect trusted apps.';

    return FCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Apps',
                  style: context.theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                Text(
                  subtitle,
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spaces.medium),
          FSwitch(value: enableXswd, onChange: _onXswdSwitch),
        ],
      ),
    );
  }

  Widget _buildStatePanel({
    required Key key,
    required IconData icon,
    required String title,
    required String description,
    required Widget trailing,
  }) {
    return SizedBox(
      key: key,
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 320),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spaces.medium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: context.theme.colors.mutedForeground,
                ),
                const SizedBox(height: Spaces.large),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.theme.typography.xl.copyWith(
                    color: context.theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: Spaces.small),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: Spaces.medium),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppsList(BuildContext context, List<AppInfo> apps) {
    final muted = context.theme.colors.mutedForeground;

    return SizedBox(
      key: const ValueKey<String>('xswd-enabled-list'),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Connected Apps',
                  style: context.theme.typography.xl.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildConnectionStatusBadge(
                context,
                ref.read(appLocalizationsProvider),
                enableXswd: true,
              ),
            ],
          ),
          const SizedBox(height: Spaces.medium),
          FItemGroup.builder(
            count: apps.length,
            itemBuilder: (BuildContext context, int index) {
              final app = apps[index];
              final permissionCount = app.permissions.length;
              final permissionText = permissionCount == 1
                  ? '1 permission'
                  : '$permissionCount permissions';

              return FItem(
                onPress: () =>
                    XswdAppDetailRoute($extra: app.id).push<void>(context),
                prefix: Icon(
                  FIcons.cable,
                  size: 18,
                  color: context.theme.colors.primary,
                ),
                title: Text(app.name),
                subtitle: app.url != null && app.url!.isNotEmpty
                    ? Text(
                        app.url!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                details: Text(
                  permissionText,
                  style: context.theme.typography.xs.copyWith(color: muted),
                ),
                suffix: Icon(FIcons.chevronRight, color: muted),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBadge(
    BuildContext context,
    AppLocalizations loc, {
    required bool enableXswd,
  }) {
    if (!enableXswd) {
      return FBadge(
        style: FBadgeStyle.secondary(),
        child: Text(loc.disabled.capitalize()),
      );
    }

    final isRelay =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    final statusText = isRelay
        ? 'Relay mode'
        : (_isXswdRunning
              ? loc.running.capitalize()
              : loc.stopped.capitalize());

    if (isRelay || _isXswdRunning) {
      return FBadge(style: FBadgeStyle.primary(), child: Text(statusText));
    }

    return FBadge(style: FBadgeStyle.destructive(), child: Text(statusText));
  }

  Widget _buildFooter(BuildContext context, bool enableXswd) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(
            top: BorderSide(color: context.theme.colors.border, width: 1),
          ),
        ),
        padding: const EdgeInsets.all(Spaces.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!enableXswd) ...[
              Text(
                'Turn on Connected Apps to add a new application.',
                textAlign: TextAlign.center,
                style: context.theme.typography.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: Spaces.small),
            ],
            FButton(
              style: FButtonStyle.primary(),
              onPress: enableXswd
                  ? () {
                      showAppDialog<void>(
                        context: context,
                        builder: (context, style, animation) =>
                            XswdNewConnectionDialog(style, animation),
                      );
                    }
                  : null,
              prefix: const Icon(FIcons.qrCode, size: 18),
              child: const Text('New Connection'),
            ),
          ],
        ),
      ),
    );
  }

  void _onXswdSwitch(bool enabled) {
    ref.read(settingsProvider.notifier).setEnableXswd(enabled);
  }
}
