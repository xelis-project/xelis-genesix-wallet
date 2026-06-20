import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
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
  static const _xswdStartupGrace = Duration(seconds: 15);

  final _scrollController = ScrollController();
  Timer? _statusCheckTimer;
  bool _isXswdRunning = false;
  DateTime? _xswdEnableRequestedAt;

  @override
  void initState() {
    super.initState();

    if (isDesktopDevice) {
      _checkXswdStatus();
      _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _checkXswdStatus();
      });
    }
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkXswdStatus() async {
    final repository = ref.read(activeWalletRepositoryProvider);
    if (repository != null) {
      try {
        final isRunning = await repository.isXswdRunning();
        if (mounted) {
          if (isRunning) {
            _xswdEnableRequestedAt = null;
          }
          setState(() {
            _isXswdRunning = isRunning;
          });
        }
      } catch (_) {
        // Silently fail: server may be unavailable.
      }
    }
  }

  bool get _isRelayMode => kIsWeb || isMobileDevice;

  bool _isConnectionReady(bool enableXswd) {
    if (!enableXswd) return false;
    return _isRelayMode || _isXswdRunning;
  }

  bool _isConnectionStopped(bool enableXswd) {
    if (!enableXswd) return false;
    if (_isRelayMode) return false;
    return !_isXswdRunning;
  }

  bool _isStartupTimedOut(bool enableXswd) {
    if (!enableXswd || _isRelayMode || _isXswdRunning) return false;
    final requestedAt = _xswdEnableRequestedAt;
    if (requestedAt == null) return true;
    return DateTime.now().difference(requestedAt) >= _xswdStartupGrace;
  }

  void _onXswdSwitch(bool enabled) {
    setState(() {
      if (enabled) {
        _xswdEnableRequestedAt ??= DateTime.now();
      } else {
        _xswdEnableRequestedAt = null;
      }

      if (isDesktopDevice) {
        // Prevent stale "running" UI while local server restarts.
        _isXswdRunning = false;
      }
    });

    ref.read(settingsProvider.notifier).setEnableXswd(enabled);

    if (enabled && isDesktopDevice) {
      unawaited(_checkXswdStatus());
    }
  }

  void _openNewConnectionDialog(BuildContext context) {
    showAppDialog<void>(
      context: context,
      builder: (context, _, animation) => XswdNewConnectionDialog(animation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final enableXswd = ref.watch(
      settingsProvider.select((settings) => settings.enableXswd),
    );
    final isConnectionReady = _isConnectionReady(enableXswd);
    final isConnectionStopped = _isConnectionStopped(enableXswd);
    final isStartupTimedOut = _isStartupTimedOut(enableXswd);
    final lockSwitchWhileStarting = isConnectionStopped && !isStartupTimedOut;
    final appsAsync = ref.watch(xswdApplicationsProvider);

    final stateBody = enableXswd
        ? appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return _XswdStatePanel(
                  key: const ValueKey<String>('xswd-enabled-empty'),
                  icon: FLucideIcons.link,
                  title: loc.no_application_connected,
                  description: 'Use New Connection to add a trusted app.',
                );
              }
              return _XswdAppsList(
                key: const ValueKey<String>('xswd-enabled-list'),
                loc: loc,
                apps: apps,
              );
            },
            loading: () => const Center(
              key: ValueKey<String>('xswd-loading'),
              child: FCircularProgress(),
            ),
            error: (error, stack) => Center(
              key: const ValueKey<String>('xswd-error'),
              child: Text('Error loading connected apps: $error'),
            ),
          )
        : _XswdStatePanel(
            key: const ValueKey<String>('xswd-disabled'),
            icon: FLucideIcons.cable,
            title: 'Connected Apps is off',
            description: 'Turn it on to approve requests from trusted apps.',
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
                  _XswdModeCard(
                    loc: loc,
                    enableXswd: enableXswd,
                    isRelayMode: _isRelayMode,
                    isRunning: _isXswdRunning,
                    lockSwitchWhileStarting: lockSwitchWhileStarting,
                    isStartupTimedOut: isStartupTimedOut,
                    onSwitchChange: _onXswdSwitch,
                  ),
                  const SizedBox(height: Spaces.large),
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: AppDurations.animNormal,
                    ),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          ...previousChildren,
                          ...<Widget?>[currentChild].whereType<Widget>(),
                        ],
                      );
                    },
                    child: stateBody,
                  ),
                ],
              ),
            ),
          ),
        ),
        _XswdFooter(
          enableXswd: enableXswd,
          isConnectionReady: isConnectionReady,
          isConnectionStopped: isConnectionStopped,
          isStartupTimedOut: isStartupTimedOut,
          onNewConnection: () => _openNewConnectionDialog(context),
        ),
      ],
    );
  }
}

class _XswdModeCard extends StatelessWidget {
  const _XswdModeCard({
    required this.loc,
    required this.enableXswd,
    required this.isRelayMode,
    required this.isRunning,
    required this.lockSwitchWhileStarting,
    required this.isStartupTimedOut,
    required this.onSwitchChange,
  });

  final AppLocalizations loc;
  final bool enableXswd;
  final bool isRelayMode;
  final bool isRunning;
  final bool lockSwitchWhileStarting;
  final bool isStartupTimedOut;
  final ValueChanged<bool> onSwitchChange;

  String _buildSubtitle() {
    if (lockSwitchWhileStarting) {
      return 'Starting local service...';
    }
    if (isStartupTimedOut && enableXswd) {
      return 'Startup is taking longer than expected.';
    }
    if (enableXswd) {
      return 'Manage connected apps and their permissions.';
    }
    return 'Turn this on to connect trusted apps.';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle();

    final canDisableAfterTimeout =
        enableXswd && isStartupTimedOut && !lockSwitchWhileStarting;

    final switchOnChange = lockSwitchWhileStarting
        ? null
        : canDisableAfterTimeout
        ? (bool value) {
            // Recovery path: allow disabling only when startup timed out.
            if (!value) onSwitchChange(false);
          }
        : onSwitchChange;

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Apps',
                  style: context.theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spaces.extraSmall),
                Text(
                  subtitle,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: Spaces.small),
                _XswdConnectionStatusLabel(
                  loc: loc,
                  enableXswd: enableXswd,
                  isRelayMode: isRelayMode,
                  isRunning: isRunning,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spaces.medium),
          FSwitch(value: enableXswd, onChange: switchOnChange),
        ],
      ),
    );
  }
}

class _XswdStatePanel extends StatelessWidget {
  const _XswdStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                  style: context.theme.typography.body.xl.copyWith(
                    color: context.theme.colors.foreground,
                  ),
                ),
                const SizedBox(height: Spaces.small),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XswdAppsList extends ConsumerStatefulWidget {
  const _XswdAppsList({super.key, required this.loc, required this.apps});

  final AppLocalizations loc;
  final List<AppInfo> apps;

  @override
  ConsumerState<_XswdAppsList> createState() => _XswdAppsListState();
}

class _XswdAppsListState extends ConsumerState<_XswdAppsList> {
  String? _disconnectingAppId;

  bool get _isDisconnecting => _disconnectingAppId != null;

  Future<void> _handleAppDisconnection(AppInfo app) async {
    try {
      await ref.read(xswdControllerProvider).closeXswdAppConnection(app);
    } catch (_) {
      // Errors are surfaced through wallet effects.
    }
  }

  Future<void> _openAppDetails(BuildContext context, AppInfo app) async {
    if (_isDisconnecting) return;

    final hasDisconnected = await XswdAppDetailRoute(
      $extra: app.id,
    ).push<bool>(context);

    if (hasDisconnected == true) {
      if (!mounted) return;
      setState(() {
        _disconnectingAppId = app.id;
      });
      await _handleAppDisconnection(app);
      if (mounted) {
        setState(() {
          _disconnectingAppId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected Apps',
                style: context.theme.typography.body.xl.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spaces.medium),
              FItemGroup.builder(
                count: widget.apps.length,
                itemBuilder: (BuildContext context, int index) {
                  final app = widget.apps[index];
                  final permissionCount = app.permissions.length;
                  final permissionText = permissionCount == 1
                      ? '1 permission'
                      : '$permissionCount permissions';

                  return FItem(
                    onPress: _isDisconnecting
                        ? null
                        : () => _openAppDetails(context, app),
                    prefix: Icon(
                      FLucideIcons.cable,
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
                      style: context.theme.typography.body.xs.copyWith(color: muted),
                    ),
                    suffix: Icon(FLucideIcons.chevronRight, color: muted),
                  );
                },
              ),
            ],
          ),
        ),
        if (_isDisconnecting)
          Positioned.fill(
            child: ColoredBox(
              color: context.theme.colors.background.withValues(alpha: 0.55),
              child: const Center(child: FCircularProgress()),
            ),
          ),
      ],
    );
  }
}

class _XswdConnectionStatusLabel extends StatelessWidget {
  const _XswdConnectionStatusLabel({
    required this.loc,
    required this.enableXswd,
    required this.isRelayMode,
    required this.isRunning,
  });

  final AppLocalizations loc;
  final bool enableXswd;
  final bool isRelayMode;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final statusText = !enableXswd
        ? loc.disabled.capitalize()
        : isRelayMode
        ? 'Relay mode'
        : (isRunning ? loc.running.capitalize() : loc.stopped.capitalize());
    final statusColor = !enableXswd
        ? context.theme.colors.mutedForeground
        : (isRelayMode || isRunning
              ? context.theme.colors.primary
              : context.theme.colors.destructive);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Status',
          style: context.theme.typography.body.xs.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(width: Spaces.small),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: Spaces.extraSmall),
        Text(
          statusText,
          style: context.theme.typography.body.sm.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _XswdFooter extends StatelessWidget {
  const _XswdFooter({
    required this.enableXswd,
    required this.isConnectionReady,
    required this.isConnectionStopped,
    required this.isStartupTimedOut,
    required this.onNewConnection,
  });

  final bool enableXswd;
  final bool isConnectionReady;
  final bool isConnectionStopped;
  final bool isStartupTimedOut;
  final VoidCallback onNewConnection;

  @override
  Widget build(BuildContext context) {
    final helperText = !enableXswd
        ? 'Turn on Connected Apps to add a new application.'
        : isConnectionStopped
        ? (isStartupTimedOut
              ? 'Startup is taking longer than expected. You can disable and retry.'
              : 'Connected Apps is starting. Actions are temporarily disabled.')
        : null;

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
            if (helperText != null) ...[
              Text(
                helperText,
                textAlign: TextAlign.center,
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: Spaces.small),
            ],
            FButton(
              onPress: isConnectionReady ? onNewConnection : null,
              prefix: const Icon(FLucideIcons.qrCode, size: 18),
              child: const Text('New Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
