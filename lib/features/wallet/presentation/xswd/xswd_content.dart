import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:genesix/features/router/routes.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_lifecycle_provider.dart';
import 'package:genesix/features/wallet/application/xswd_notification_service.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/xswd_lifecycle_state.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isRelayMode => kIsWeb || Platform.isIOS;

  bool _isConnectionReady(bool enableXswd, XswdLifecycleState lifecycle) {
    if (!enableXswd) return false;
    return _isRelayMode || lifecycle.isRunning;
  }

  bool _isConnectionStopped(bool enableXswd, XswdLifecycleState lifecycle) {
    if (!enableXswd) return false;
    if (_isRelayMode) return false;
    return !lifecycle.isRunning;
  }

  void _onXswdSwitch(bool enabled) {
    if (ref.read(settingsProvider).walletOfflineMode) {
      return;
    }

    if (enabled && !ref.read(xswdControllerProvider).ensureNodeAvailable()) {
      return;
    }

    ref.read(settingsProvider.notifier).setEnableXswd(enabled);
    if (enabled) {
      unawaited(
        ref
            .read(xswdNotificationServiceProvider)
            .requestPermissionFromUserAction(),
      );
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
    final walletOfflineMode = ref.watch(
      settingsProvider.select((settings) => settings.walletOfflineMode),
    );
    final enableXswd = ref.watch(effectiveXswdEnabledProvider);
    final lifecycle = ref.watch(xswdLifecycleProvider);
    final isConnectionReady = _isConnectionReady(enableXswd, lifecycle);
    final isConnectionStopped = _isConnectionStopped(enableXswd, lifecycle);
    final isStartupTimedOut = lifecycle.hasFailed;
    final lockSwitchWhileStarting =
        lifecycle.isStarting || lifecycle.isStopping;
    final appsAsync = ref.watch(xswdApplicationsProvider);

    final stateBody = walletOfflineMode
        ? _XswdStatePanel(
            key: const ValueKey<String>('xswd-offline-disabled'),
            icon: FLucideIcons.cable,
            title: loc.xswd_disabled_offline_title,
            description: loc.xswd_disabled_offline_description,
          )
        : enableXswd
        ? appsAsync.when(
            data: (apps) {
              if (apps.isEmpty) {
                return _XswdStatePanel(
                  key: const ValueKey<String>('xswd-enabled-empty'),
                  icon: FLucideIcons.link,
                  title: loc.no_application_connected,
                  description: loc.xswd_empty_enabled_description,
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
              child: Text('${loc.error_loading_applications}: $error'),
            ),
          )
        : _XswdStatePanel(
            key: const ValueKey<String>('xswd-disabled'),
            icon: FLucideIcons.cable,
            title: loc.xswd_disabled_title,
            description: loc.xswd_disabled_description,
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
                    isOfflineMode: walletOfflineMode,
                    isRelayMode: _isRelayMode,
                    isRunning: lifecycle.isRunning,
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
          loc: loc,
          enableXswd: enableXswd,
          isOfflineMode: walletOfflineMode,
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
    required this.isOfflineMode,
    required this.isRelayMode,
    required this.isRunning,
    required this.lockSwitchWhileStarting,
    required this.isStartupTimedOut,
    required this.onSwitchChange,
  });

  final AppLocalizations loc;
  final bool enableXswd;
  final bool isOfflineMode;
  final bool isRelayMode;
  final bool isRunning;
  final bool lockSwitchWhileStarting;
  final bool isStartupTimedOut;
  final ValueChanged<bool> onSwitchChange;

  String? _buildSubtitle() {
    if (isOfflineMode) {
      return null;
    }
    if (lockSwitchWhileStarting) {
      return loc.xswd_starting_local_service;
    }
    if (isStartupTimedOut && enableXswd) {
      return loc.xswd_startup_delayed;
    }
    if (enableXswd) {
      return loc.xswd_enabled_description;
    }
    return loc.xswd_disabled_subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle();

    final canDisableAfterTimeout =
        enableXswd && isStartupTimedOut && !lockSwitchWhileStarting;

    final switchOnChange = isOfflineMode || lockSwitchWhileStarting
        ? null
        : canDisableAfterTimeout
        ? (bool value) {
            // Recovery path: allow disabling only when startup timed out.
            if (!value) onSwitchChange(false);
          }
        : onSwitchChange;

    return AppCard(
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.connected_apps,
                  style: context.theme.typography.display.lg,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Spaces.extraSmall),
                  Text(
                    subtitle,
                    style: context.theme.typography.body.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
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
                  style: context.theme.typography.display.xl.copyWith(
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
                widget.loc.connected_apps,
                style: context.theme.typography.display.xl,
              ),
              const SizedBox(height: Spaces.medium),
              FItemGroup.builder(
                count: widget.apps.length,
                itemBuilder: (BuildContext context, int index) {
                  final app = widget.apps[index];
                  final permissionCount = app.permissions.length;
                  final permissionText = permissionCount == 1
                      ? widget.loc.one_permission
                      : widget.loc.permission_count(permissionCount);

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
                      style: context.theme.typography.body.xs.copyWith(
                        color: muted,
                      ),
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
        ? loc.xswd_relay_mode
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
          loc.status,
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
    required this.loc,
    required this.enableXswd,
    required this.isOfflineMode,
    required this.isConnectionReady,
    required this.isConnectionStopped,
    required this.isStartupTimedOut,
    required this.onNewConnection,
  });

  final AppLocalizations loc;
  final bool enableXswd;
  final bool isOfflineMode;
  final bool isConnectionReady;
  final bool isConnectionStopped;
  final bool isStartupTimedOut;
  final VoidCallback onNewConnection;

  @override
  Widget build(BuildContext context) {
    final helperText = isOfflineMode
        ? null
        : !enableXswd
        ? loc.xswd_enable_before_new_connection
        : isConnectionStopped
        ? (isStartupTimedOut
              ? loc.xswd_startup_retry_hint
              : loc.xswd_starting_actions_disabled)
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
              onPress: !isOfflineMode && isConnectionReady
                  ? onNewConnection
                  : null,
              prefix: const Icon(FLucideIcons.qrCode, size: 18),
              child: Text(loc.new_connection),
            ),
          ],
        ),
      ),
    );
  }
}
