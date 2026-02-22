import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/features/wallet/domain/prefetch_permissions_rpc_request.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/burn_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/deploy_contract_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_contract_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/multisig_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transfer_builder_widget.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class XswdDialog extends ConsumerStatefulWidget {
  const XswdDialog(this.animation, {super.key});

  final Animation<double> animation;

  @override
  ConsumerState createState() => _XswdDialogState();
}

enum _ActionSet {
  okOnly,
  permissionDecision, // Allow / Always allow / Always deny / Deny
  connectionDecision, // Allow / Deny
  prefetchDecision, // Allow / Deny
}

class _XswdDialogState extends ConsumerState<XswdDialog> {
  static const int _requestLifetime = 60000;
  static const Duration _rapidFireWindow = Duration(milliseconds: 500);

  int _millisecondsLeft = _requestLifetime;
  double _progress = 1.0;
  Timer? _timer;

  Timer? _closeDelayTimer;
  bool _awaitingNextRequest = false;
  int? _awaitingRequestHash;

  late final ScrollController _scrollController;

  bool _timerShouldRun = false;
  bool _rememberDecision = false;

  late final XswdRequest _xswdRequestNotifier;

  @override
  void initState() {
    super.initState();
    _xswdRequestNotifier = ref.read(xswdRequestProvider.notifier);
    _scrollController = ScrollController();
  }

  void _setSuppress(bool value) {
    _xswdRequestNotifier.setSuppressXswdToast(value);
  }

  void _startTimer() {
    _timer?.cancel();
    _millisecondsLeft = _requestLifetime;
    _progress = 1.0;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _millisecondsLeft -= 100;
        _progress = _millisecondsLeft / _requestLifetime;
      });

      if (_millisecondsLeft <= 0) {
        timer.cancel();
        _handleTimeout();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleTimeout() {
    _cancelRapidFireWait();

    final xswdState = ref.read(xswdRequestProvider);
    final decision = xswdState.decision;
    if (decision != null && !decision.isCompleted) {
      decision.complete(UserPermissionDecision.reject);
    }

    // Clear the request state to prevent stuck spinners
    ref.read(xswdRequestProvider.notifier).clearRequest();

    if (mounted) {
      context.pop();
    }
  }

  void _cancelRapidFireWait() {
    _closeDelayTimer?.cancel();
    _closeDelayTimer = null;

    _setSuppress(false);

    _awaitingNextRequest = false;
    _awaitingRequestHash = null;
  }

  void _beginRapidFireWait({required int currentRequestHash}) {
    _closeDelayTimer?.cancel();

    _setSuppress(true);

    setState(() {
      _awaitingNextRequest = true;
      _awaitingRequestHash = currentRequestHash;
    });

    _closeDelayTimer = Timer(_rapidFireWindow, () {
      if (!mounted) return;

      final latestHash = ref
          .read(xswdRequestProvider)
          .xswdEventSummary
          ?.hashCode;

      if (latestHash != null &&
          _awaitingRequestHash != null &&
          latestHash != _awaitingRequestHash) {
        setState(() {
          _awaitingNextRequest = false;
          _awaitingRequestHash = null;
        });
        _setSuppress(false);
        return;
      }

      _setSuppress(false);
      context.pop();
    });
  }

  _ActionSet _computeActionSet(XswdRequestState xswdState) {
    final summary = xswdState.xswdEventSummary;
    if (summary == null) return _ActionSet.okOnly;

    final isCancelOrDisconnect =
        summary.isCancelRequest() || summary.isAppDisconnect();

    if (isCancelOrDisconnect) return _ActionSet.okOnly;
    if (summary.isPermissionRequest()) return _ActionSet.permissionDecision;
    if (summary.isApplicationRequest()) return _ActionSet.connectionDecision;
    if (summary.isPrefetchPermissionsRequest()) {
      return _ActionSet.prefetchDecision;
    }

    return _ActionSet.okOnly;
  }

  bool _shouldRunTimerForActionSet(_ActionSet set) {
    switch (set) {
      case _ActionSet.permissionDecision:
      case _ActionSet.connectionDecision:
      case _ActionSet.prefetchDecision:
        return true;
      case _ActionSet.okOnly:
        return false;
    }
  }

  void _syncTimerWithState(_ActionSet set) {
    if (_awaitingNextRequest) {
      if (_timerShouldRun) {
        _timerShouldRun = false;
        _stopTimer();
      }
      return;
    }

    final shouldRun = _shouldRunTimerForActionSet(set);

    if (shouldRun && !_timerShouldRun) {
      _timerShouldRun = true;
      _startTimer();
      return;
    }

    if (!shouldRun && _timerShouldRun) {
      _timerShouldRun = false;
      _stopTimer();
      return;
    }
  }

  @override
  void dispose() {
    _closeDelayTimer?.cancel();
    _timer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setSuppress(false);
    });

    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final xswdState = ref.watch(xswdRequestProvider);

    if (xswdState.xswdEventSummary == null) {
      _cancelRapidFireWait();
      _syncTimerWithState(_ActionSet.okOnly);

      return FDialog(
        animation: widget.animation,
        body: Center(
          child: Text(
            loc.unknown_request.capitalize(),
            style: context.headlineSmall,
          ),
        ),
        actions: [
          FButton(
            variant: .ghost,
            onPress: () {
              final decision = xswdState.decision;
              if (decision != null && !decision.isCompleted) {
                decision.complete(UserPermissionDecision.reject);
              }
              // Clear the request state
              ref.read(xswdRequestProvider.notifier).clearRequest();
              context.pop();
            },
            child: Text(loc.close),
          ),
        ],
      );
    }

    final summary = xswdState.xswdEventSummary!;
    final currentHash = summary.hashCode;

    if (_awaitingNextRequest &&
        _awaitingRequestHash != null &&
        currentHash != _awaitingRequestHash) {
      _closeDelayTimer?.cancel();
      _closeDelayTimer = null;
      _awaitingNextRequest = false;
      _awaitingRequestHash = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setSuppress(false);
      });

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }

    final actionSet = _computeActionSet(xswdState);
    _syncTimerWithState(actionSet);

    final eventType = summary.eventType;
    final isCancelOrDisconnect =
        summary.isCancelRequest() || summary.isAppDisconnect();

    String title;
    switch (eventType) {
      case XswdRequestType_Application():
        title = loc.connection_request.capitalize();
      case XswdRequestType_Permission():
        title = loc.permission_request.capitalize();
      case XswdRequestType_PrefetchPermissions():
        title = loc.prefetch_permissions_request.capitalize();
      case XswdRequestType_CancelRequest():
        title = loc.cancellation_request.capitalize();
      case XswdRequestType_AppDisconnect():
        title = loc.app_disconnected.capitalize();
    }

    return FDialog(
      animation: widget.animation,
      constraints: const BoxConstraints(maxWidth: 700),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxBodyHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight * 0.82
              : 620.0;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spaces.extraSmall),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (!isCancelOrDisconnect) ...[
                        _XswdCountdownIndicator(
                          awaitingNextRequest: _awaitingNextRequest,
                          millisecondsLeft: _millisecondsLeft,
                          progress: _progress,
                        ),
                        const SizedBox(width: Spaces.medium),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: context.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (!isCancelOrDisconnect) ...[
                        const SizedBox(width: Spaces.medium),
                        // X = explicit dismissal -> close immediately, no rapid-fire wait.
                        FTooltip(
                          tipBuilder: (context, controller) => Text(loc.close),
                          child: FButton.icon(
                            variant: .ghost,
                            onPress: () {
                              _stopTimer();
                              _cancelRapidFireWait();

                              // Complete decision as reject before closing
                              final decision = ref
                                  .read(xswdRequestProvider)
                                  .decision;
                              if (decision != null && !decision.isCompleted) {
                                decision.complete(
                                  UserPermissionDecision.reject,
                                );
                              }

                              // Clear the request state to prevent stuck spinners
                              ref
                                  .read(xswdRequestProvider.notifier)
                                  .clearRequest();

                              context.pop();
                            },
                            child: const Icon(FIcons.x, size: 22),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Spaces.small),
                Flexible(
                  child: FadedScroll(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spaces.small,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _XswdApplicationInfoSection(
                            appInfo: summary.applicationInfo,
                            loc: loc,
                          ),
                          const SizedBox(height: Spaces.medium),
                          _XswdMoreDetailsAccordion(
                            appInfo: summary.applicationInfo,
                            permissionRequest: xswdState.permissionRpcRequest,
                            prefetchRequest:
                                xswdState.prefetchPermissionsRequest,
                            loc: loc,
                            onAssetTap: (asset) =>
                                _showAssetDetails(context, loc, asset),
                          ),
                          const SizedBox(height: Spaces.small),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: _XswdActionFactory(
        actionSet: actionSet,
        busy: _awaitingNextRequest,
        rememberDecision: _rememberDecision,
        loc: loc,
        onRememberChanged: (value) {
          setState(() {
            _rememberDecision = value;
          });
        },
        onDecision: _handleDecision,
      ).build(context),
    );
  }

  void _showAssetDetails(
    BuildContext context,
    AppLocalizations loc,
    String asset,
  ) {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Row(
          children: [
            const Icon(FIcons.coins),
            const SizedBox(width: Spaces.small),
            Expanded(child: Text(loc.details.capitalize())),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.asset,
                style: context.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: Spaces.extraSmall),
              SelectableText(asset, style: context.bodySmall),
            ],
          ),
        ),
        actions: [
          FButton(onPress: () => context.pop(), child: Text(loc.close)),
        ],
      ),
    );
  }

  void _handleDecision(UserPermissionDecision decision) {
    _stopTimer();

    final xswdState = ref.read(xswdRequestProvider);
    final decisionCompleter = xswdState.decision;
    if (decisionCompleter != null && !decisionCompleter.isCompleted) {
      decisionCompleter.complete(decision);
    }

    final currentHash = xswdState.xswdEventSummary?.hashCode;
    if (currentHash != null) {
      _beginRapidFireWait(currentRequestHash: currentHash);
      return;
    }

    context.pop();
  }
}

class _XswdInfoRow extends StatelessWidget {
  const _XswdInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.bodyMedium?.copyWith(color: muted)),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(value, style: context.bodyLarge),
      ],
    );
  }
}

class _XswdApplicationInfoSection extends StatelessWidget {
  const _XswdApplicationInfoSection({required this.appInfo, required this.loc});

  final AppInfo appInfo;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final url = appInfo.url?.trim();
    final displayUrl = (url != null && url.isNotEmpty) ? url : '-';

    return Container(
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactLayout = constraints.maxWidth < 520;

          if (compactLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _XswdInfoRow(label: loc.name.capitalize(), value: appInfo.name),
                const SizedBox(height: Spaces.medium),
                _XswdInfoRow(label: loc.url.capitalize(), value: displayUrl),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _XswdInfoRow(
                  label: loc.name.capitalize(),
                  value: appInfo.name,
                ),
              ),
              const SizedBox(width: Spaces.medium),
              Expanded(
                child: _XswdInfoRow(
                  label: loc.url.capitalize(),
                  value: displayUrl,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _XswdMoreDetailsAccordion extends StatelessWidget {
  const _XswdMoreDetailsAccordion({
    required this.appInfo,
    required this.permissionRequest,
    required this.prefetchRequest,
    required this.loc,
    required this.onAssetTap,
  });

  final AppInfo appInfo;
  final PermissionRpcRequest? permissionRequest;
  final PrefetchPermissionsRequest? prefetchRequest;
  final AppLocalizations loc;
  final ValueChanged<String> onAssetTap;

  @override
  Widget build(BuildContext context) {
    final hasDescription = appInfo.description.isNotEmpty;
    final hasPermissionDetails = permissionRequest != null;
    final hasPrefetchDetails = prefetchRequest != null;
    final hasFuturePermissions = appInfo.permissions.isNotEmpty;

    if (!hasDescription &&
        !hasPermissionDetails &&
        !hasPrefetchDetails &&
        !hasFuturePermissions) {
      return const SizedBox.shrink();
    }

    return FAccordion(
      children: [
        FAccordionItem(
          title: const Text('More details'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDescription)
                _XswdInfoRow(
                  label: loc.description.capitalize(),
                  value: appInfo.description,
                ),
              if (hasPermissionDetails) ...[
                if (hasDescription) const SizedBox(height: Spaces.medium),
                _XswdMinimalPermissionSection(
                  request: permissionRequest!,
                  loc: loc,
                  onAssetTap: onAssetTap,
                ),
              ],
              if (hasPrefetchDetails) ...[
                if (hasDescription || hasPermissionDetails)
                  const SizedBox(height: Spaces.medium),
                _XswdMinimalPrefetchDetailsSection(
                  request: prefetchRequest!,
                  loc: loc,
                ),
              ],
              if (hasFuturePermissions) ...[
                if (hasDescription ||
                    hasPermissionDetails ||
                    hasPrefetchDetails)
                  const SizedBox(height: Spaces.medium),
                _XswdMinimalFuturePermissionsSection(
                  permissions: appInfo.permissions.keys,
                  loc: loc,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _XswdMinimalPermissionSection extends StatelessWidget {
  const _XswdMinimalPermissionSection({
    required this.request,
    required this.loc,
    required this.onAssetTap,
  });

  final PermissionRpcRequest request;
  final AppLocalizations loc;
  final ValueChanged<String> onAssetTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    final hasParams = request.params != null && request.params!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.permissions.capitalize(),
          style: context.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.small),
        _XswdMinimalBadge(label: request.method),
        if (hasParams) ...[
          const SizedBox(height: Spaces.small),
          Text(
            loc.details.capitalize(),
            style: context.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: Spaces.extraSmall),
          _XswdPermissionPayload(
            request: request,
            loc: loc,
            onAssetTap: onAssetTap,
          ),
        ],
      ],
    );
  }
}

class _XswdMinimalPrefetchDetailsSection extends StatelessWidget {
  const _XswdMinimalPrefetchDetailsSection({
    required this.request,
    required this.loc,
  });

  final PrefetchPermissionsRequest request;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (request.reason != null && request.reason!.isNotEmpty) ...[
          _XswdInfoRow(label: 'Reason', value: request.reason!),
          const SizedBox(height: Spaces.medium),
        ],
        Text(
          loc.permissions.capitalize(),
          style: context.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.small),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: request.permissions
              .map((permission) => _XswdMinimalBadge(label: permission))
              .toList(),
        ),
      ],
    );
  }
}

class _XswdMinimalFuturePermissionsSection extends StatelessWidget {
  const _XswdMinimalFuturePermissionsSection({
    required this.permissions,
    required this.loc,
  });

  final Iterable<String> permissions;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.future_permissions.capitalize(),
          style: context.bodyMedium?.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.small),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: permissions
              .map((permission) => _XswdMinimalBadge(label: permission))
              .toList(),
        ),
      ],
    );
  }
}

class _XswdMinimalBadge extends StatelessWidget {
  const _XswdMinimalBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FBadge(variant: .outline, child: Text(label));
  }
}

class _XswdPermissionPayload extends StatelessWidget {
  const _XswdPermissionPayload({
    required this.request,
    required this.loc,
    required this.onAssetTap,
  });

  final PermissionRpcRequest request;
  final AppLocalizations loc;
  final ValueChanged<String> onAssetTap;

  @override
  Widget build(BuildContext context) {
    Widget? builderWidget;

    if (request.params == null || request.params!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (request.method == WalletMethod.buildTransaction.jsonKey) {
      final params = BuildTransactionParams.fromJson(request.params!);
      final builder = params.transactionTypeBuilder;

      if (builder is TransfersBuilder) {
        builderWidget = TransfersBuilderWidget(transfersBuilder: builder);
      } else if (builder is BurnBuilder) {
        builderWidget = BurnBuilderWidget(burnBuilder: builder);
      } else if (builder is MultisigBuilder) {
        builderWidget = MultisigBuilderWidget(multisigBuilder: builder);
      } else if (builder is InvokeContractBuilder) {
        builderWidget = InvokeContractBuilderWidget(
          invokeContractBuilder: builder,
        );
      } else if (builder is DeployContractBuilder) {
        builderWidget = DeployContractBuilderWidget(
          deployContractBuilder: builder,
        );
      }
    } else if (request.params!.length == 1 &&
        request.params!.containsKey('asset') &&
        request.params!['asset'] is String) {
      final asset = request.params!['asset'] as String;
      builderWidget = Wrap(
        spacing: Spaces.small,
        runSpacing: Spaces.small,
        children: [
          _AssetPermissionBadge(
            asset: asset,
            assetLabel: loc.asset,
            onTap: () => onAssetTap(asset),
          ),
        ],
      );
    }

    final Widget content =
        builderWidget ??
        SelectableText(
          const JsonEncoder.withIndent('  ').convert(request.params),
          style: context.bodySmall?.copyWith(fontFamily: 'monospace'),
        );

    return _PermissionContentContainer(
      child: SingleChildScrollView(child: content),
    );
  }
}

class _XswdActionFactory {
  const _XswdActionFactory({
    required this.actionSet,
    required this.busy,
    required this.rememberDecision,
    required this.loc,
    required this.onRememberChanged,
    required this.onDecision,
  });

  final _ActionSet actionSet;
  final bool busy;
  final bool rememberDecision;
  final AppLocalizations loc;
  final ValueChanged<bool> onRememberChanged;
  final ValueChanged<UserPermissionDecision> onDecision;

  List<Widget> build(BuildContext context) {
    switch (actionSet) {
      case _ActionSet.okOnly:
        return [
          FButton(
            onPress: busy ? null : () => context.pop(),
            child: Text(loc.ok_button),
          ),
        ];

      case _ActionSet.connectionDecision:
      case _ActionSet.prefetchDecision:
        return _buildBinaryDecisionActions(
          context: context,
          busy: busy,
          denyLabel: loc.deny,
          allowLabel: loc.allow,
          onDeny: () => onDecision(UserPermissionDecision.reject),
          onAllow: () => onDecision(UserPermissionDecision.accept),
        );

      case _ActionSet.permissionDecision:
        return [
          FSwitch(
            label: const Text('Remember my decision'),
            value: rememberDecision,
            onChange: busy ? null : onRememberChanged,
          ),
          const SizedBox(height: Spaces.extraSmall),
          ..._buildBinaryDecisionActions(
            context: context,
            busy: busy,
            denyLabel: loc.deny,
            allowLabel: loc.allow,
            onDeny: () {
              final decision = rememberDecision
                  ? UserPermissionDecision.alwaysReject
                  : UserPermissionDecision.reject;
              onDecision(decision);
            },
            onAllow: () {
              final decision = rememberDecision
                  ? UserPermissionDecision.alwaysAccept
                  : UserPermissionDecision.accept;
              onDecision(decision);
            },
          ),
        ];
    }
  }

  List<Widget> _buildBinaryDecisionActions({
    required BuildContext context,
    required bool busy,
    required String denyLabel,
    required String allowLabel,
    required VoidCallback onDeny,
    required VoidCallback onAllow,
  }) {
    return [
      Row(
        children: [
          _XswdDecisionButton(
            busy: busy,
            label: denyLabel,
            variant: .outline,
            onPress: onDeny,
          ),
          const SizedBox(width: Spaces.small),
          _XswdDecisionButton(busy: busy, label: allowLabel, onPress: onAllow),
        ],
      ),
    ];
  }
}

class _XswdDecisionButton extends StatelessWidget {
  const _XswdDecisionButton({
    required this.busy,
    required this.label,
    this.variant,
    required this.onPress,
  });

  final bool busy;
  final String label;
  final FButtonVariant? variant;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FButton(
        variant: variant,
        onPress: busy ? null : onPress,
        child: Text(label),
      ),
    );
  }
}

class _XswdCountdownIndicator extends StatelessWidget {
  const _XswdCountdownIndicator({
    required this.awaitingNextRequest,
    required this.millisecondsLeft,
    required this.progress,
  });

  final bool awaitingNextRequest;
  final int millisecondsLeft;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final secondsLeft = (millisecondsLeft / 1000).ceil();
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(40),
            painter: _CountdownRingPainter(
              progress: awaitingNextRequest ? null : clampedProgress,
              trackColor: colors.border,
              activeColor: colors.primary,
            ),
          ),
          if (awaitingNextRequest)
            FInheritedCircularProgressStyle(
              style: FCircularProgressStyle(
                iconStyle: IconThemeData(size: 16, color: colors.primary),
              ),
              child: const FCircularProgress.loader(),
            )
          else
            Text(
              '$secondsLeft',
              style: context.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class _XswdIconBadge extends StatelessWidget {
  const _XswdIconBadge({this.variant, required this.icon, required this.child});

  final FBadgeVariant? variant;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FBadge(
      variant: variant,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.theme.colors.mutedForeground),
          const SizedBox(width: Spaces.extraSmall),
          child,
        ],
      ),
    );
  }
}

class _AssetPermissionBadge extends StatelessWidget {
  const _AssetPermissionBadge({
    required this.asset,
    required this.assetLabel,
    required this.onTap,
  });

  final String asset;
  final String assetLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final truncated = asset.length > 16
        ? '${asset.substring(0, 8)}...${asset.substring(asset.length - 6)}'
        : asset;

    return GestureDetector(
      onTap: onTap,
      child: _XswdIconBadge(
        variant: .outline,
        icon: FIcons.coins,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  assetLabel,
                  style: context.bodySmall?.copyWith(
                    color: context.theme.colors.mutedForeground,
                    fontSize: 11,
                  ),
                ),
                Text(truncated, style: context.bodySmall),
              ],
            ),
            if (asset.length > 16) ...[
              const SizedBox(width: Spaces.extraSmall),
              Icon(
                FIcons.circleQuestionMark,
                size: 14,
                color: context.theme.colors.mutedForeground,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionContentContainer extends StatelessWidget {
  const _PermissionContentContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  const _CountdownRingPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
  });

  final double? progress;
  final Color trackColor;
  final Color activeColor;
  static const double _strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);

    final value = progress;
    if (value == null) {
      return;
    }

    final clamped = value.clamp(0.0, 1.0).toDouble();
    final sweep = 2 * math.pi * clamped;
    if (sweep <= 0) {
      return;
    }

    final arc = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor;
  }
}
