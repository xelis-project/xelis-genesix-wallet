import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/burn_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/deploy_contract_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_contract_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/multisig_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transfer_builder_widget.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class XswdDialog extends ConsumerStatefulWidget {
  const XswdDialog(this.style, this.animation, {super.key});

  final FDialogStyle style;
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
  static const Duration _rapidFireWindow = Duration(milliseconds: 300);

  int _millisecondsLeft = _requestLifetime;
  double _progress = 1.0;
  Timer? _timer;

  Timer? _closeDelayTimer;
  bool _awaitingNextRequest = false;
  int? _awaitingRequestHash;

  late final ScrollController _scrollController;
  bool _showTopFade = false;
  bool _showBottomFade = false;

  bool _timerShouldRun = false;
  bool _rememberDecision = false;

  late final XswdRequest _xswdRequestNotifier;

  bool get _isDesktopLike {
    if (kIsWeb) return true;
    switch (Theme.of(context).platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _xswdRequestNotifier = ref.read(xswdRequestProvider.notifier);
    _scrollController = ScrollController()..addListener(_updateFades);
  }

  void _setSuppress(bool value) {
    _xswdRequestNotifier.setSuppressXswdToast(value);
  }

  void _updateFades() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final hasOverflow = position.maxScrollExtent > 0;

    const epsilon = 1.0;
    final atTop = position.pixels <= epsilon;
    final atBottom = position.pixels >= (position.maxScrollExtent - epsilon);

    final newTop = hasOverflow && !atTop;
    final newBottom = hasOverflow && !atBottom;

    if (newTop != _showTopFade || newBottom != _showBottomFade) {
      setState(() {
        _showTopFade = newTop;
        _showBottomFade = newBottom;
      });
    }
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

  Widget _busyLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: Spaces.small),
        Text(text),
      ],
    );
  }

  @override
  void dispose() {
    _closeDelayTimer?.cancel();
    _timer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setSuppress(false);
    });

    _scrollController
      ..removeListener(_updateFades)
      ..dispose();

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
        style: widget.style,
        animation: widget.animation,
        body: Center(
          child: Text(
            loc.unknown_request.capitalize(),
            style: context.headlineSmall,
          ),
        ),
        actions: [
          FButton(
            style: FButtonStyle.ghost(),
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
    final isPermissionRequest = summary.isPermissionRequest();
    final isApplicationRequest = summary.isApplicationRequest();
    final isPrefetchRequest = summary.isPrefetchPermissionsRequest();
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
      style: widget.style,
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
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: _awaitingNextRequest ? null : _progress,
                                strokeWidth: 3,
                                backgroundColor: context.theme.colors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.theme.colors.primary,
                                ),
                              ),
                            ),
                            if (!_awaitingNextRequest)
                              Text(
                                '${(_millisecondsLeft / 1000).ceil()}',
                                style: context.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
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
                        FButton.icon(
                          style: FButtonStyle.ghost(),
                          onPress: () {
                            _stopTimer();
                            _cancelRapidFireWait();

                            // Complete decision as reject before closing
                            final decision = ref
                                .read(xswdRequestProvider)
                                .decision;
                            if (decision != null && !decision.isCompleted) {
                              decision.complete(UserPermissionDecision.reject);
                            }

                            // Clear the request state to prevent stuck spinners
                            ref
                                .read(xswdRequestProvider.notifier)
                                .clearRequest();

                            context.pop();
                          },
                          child: const Icon(FIcons.x, size: 22),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Spaces.small),
                Flexible(
                  child: _ScrollableWithAffordances(
                    controller: _scrollController,
                    thumbAlwaysVisible: _isDesktopLike,
                    showTopFade: _showTopFade,
                    showBottomFade: _showBottomFade,
                    fadeColor: context.colors.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spaces.small,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildApplicationInfo(context, xswdState),

                        if (isPermissionRequest) ...[
                          const SizedBox(height: Spaces.large),
                          FDivider(
                            style: context.theme.dividerStyles.horizontalStyle
                                .copyWith(
                                  padding: EdgeInsets.zero,
                                  color: context.theme.colors.primary,
                                )
                                .call,
                          ),
                          const SizedBox(height: Spaces.large),
                          _buildPermissionDetails(context, xswdState),
                        ],

                        if (isPrefetchRequest) ...[
                          const SizedBox(height: Spaces.large),
                          FDivider(
                            style: context.theme.dividerStyles.horizontalStyle
                                .copyWith(
                                  padding: EdgeInsets.zero,
                                  color: context.theme.colors.primary,
                                )
                                .call,
                          ),
                          const SizedBox(height: Spaces.large),
                          _buildPrefetchDetails(context, xswdState),
                        ],

                        if (isApplicationRequest) ...[
                          const SizedBox(height: Spaces.large),
                          FDivider(
                            style: context.theme.dividerStyles.horizontalStyle
                                .copyWith(
                                  padding: EdgeInsets.zero,
                                  color: context.theme.colors.primary,
                                )
                                .call,
                          ),
                          const SizedBox(height: Spaces.large),
                          _buildFuturePermissions(context, xswdState),
                        ],

                        const SizedBox(height: Spaces.medium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: _buildActions(context, xswdState, actionSet),
    );
  }

  Widget _buildApplicationInfo(
    BuildContext context,
    XswdRequestState xswdState,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final appInfo = xswdState.xswdEventSummary!.applicationInfo;
    final muted = context.theme.colors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(context, loc.id.capitalize(), appInfo.id, muted),
        const SizedBox(height: Spaces.medium),
        _buildInfoRow(context, loc.name.capitalize(), appInfo.name, muted),
        if (appInfo.description.isNotEmpty) ...[
          const SizedBox(height: Spaces.medium),
          _buildInfoRow(
            context,
            loc.description.capitalize(),
            appInfo.description,
            muted,
          ),
        ],
        if (appInfo.url != null && appInfo.url!.isNotEmpty) ...[
          const SizedBox(height: Spaces.medium),
          _buildInfoRow(context, loc.url.capitalize(), appInfo.url!, muted),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    Color mutedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.bodyMedium?.copyWith(color: mutedColor)),
        const SizedBox(height: Spaces.extraSmall),
        SelectableText(value, style: context.bodyLarge),
      ],
    );
  }

  void _showAssetDetails(
    BuildContext context,
    AppLocalizations loc,
    String asset,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.token),
            const SizedBox(width: Spaces.small),
            Expanded(child: Text(loc.details.capitalize())),
          ],
        ),
        content: SingleChildScrollView(
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
          TextButton(onPressed: () => context.pop(), child: Text(loc.close)),
        ],
      ),
    );
  }

  Widget _buildPermissionDetails(
    BuildContext context,
    XswdRequestState xswdState,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final permissionRequest = xswdState.permissionRpcRequest;

    if (permissionRequest == null) return const SizedBox.shrink();

    final muted = context.theme.colors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.method.capitalize(),
          style: context.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.small),
        Chip(
          label: Text(permissionRequest.method),
          avatar: const Icon(Icons.code, size: 16),
        ),
        if (permissionRequest.params != null &&
            permissionRequest.params!.isNotEmpty) ...[
          const SizedBox(height: Spaces.medium),
          Text(
            loc.details.capitalize(),
            style: context.bodyLarge?.copyWith(color: muted),
          ),
          const SizedBox(height: Spaces.small),
          _handlePermissionRpcRequest(permissionRequest),
        ],
      ],
    );
  }

  Widget _handlePermissionRpcRequest(PermissionRpcRequest request) {
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
      final loc = ref.read(appLocalizationsProvider);
      final truncated = asset.length > 16
          ? '${asset.substring(0, 8)}...${asset.substring(asset.length - 6)}'
          : asset;

      builderWidget = Wrap(
        spacing: Spaces.small,
        runSpacing: Spaces.small,
        children: [
          InkWell(
            onTap: () => _showAssetDetails(context, loc, asset),
            borderRadius: BorderRadius.circular(8),
            child: Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        loc.asset,
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
                      Icons.info_outline,
                      size: 14,
                      color: context.theme.colors.mutedForeground,
                    ),
                  ],
                ],
              ),
              avatar: const Icon(Icons.token, size: 16),
            ),
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

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(child: content),
    );
  }

  Widget _buildPrefetchDetails(
    BuildContext context,
    XswdRequestState xswdState,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final prefetchRequest = xswdState.prefetchPermissionsRequest;
    final muted = context.theme.colors.mutedForeground;

    if (prefetchRequest == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prefetchRequest.reason != null &&
            prefetchRequest.reason!.isNotEmpty) ...[
          _buildInfoRow(context, 'Reason', prefetchRequest.reason!, muted),
          const SizedBox(height: Spaces.medium),
        ],
        Text(
          '${loc.permissions.capitalize()} Requested',
          style: context.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.small),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: prefetchRequest.permissions.map((permission) {
            return Chip(
              label: Text(permission),
              avatar: const Icon(Icons.verified_user, size: 16),
            );
          }).toList(),
        ),
        const SizedBox(height: Spaces.medium),
        Container(
          padding: const EdgeInsets.all(Spaces.medium),
          decoration: BoxDecoration(
            color: context.theme.colors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(FIcons.info, size: 16, color: muted),
              const SizedBox(width: Spaces.small),
              Expanded(
                child: Text(
                  'This application is requesting permission to use these features in advance. Approving will allow the app to use these permissions without asking again.',
                  style: context.bodySmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFuturePermissions(
    BuildContext context,
    XswdRequestState xswdState,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final permissions = xswdState.xswdEventSummary!.applicationInfo.permissions;
    final muted = context.theme.colors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.future_permissions.capitalize(),
          style: context.bodyLarge?.copyWith(color: muted),
        ),
        const SizedBox(height: Spaces.small),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: permissions.keys.map<Widget>((String name) {
            return Chip(
              label: Text(name),
              avatar: const Icon(Icons.code, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    XswdRequestState xswdState,
    _ActionSet actionSet,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final busy = _awaitingNextRequest;

    void decide(UserPermissionDecision d) => _handleDecision(d);

    switch (actionSet) {
      case _ActionSet.okOnly:
        return [
          FButton(
            style: FButtonStyle.primary(),
            onPress: busy ? null : () => context.pop(),
            child: Text(loc.ok_button),
          ),
        ];

      case _ActionSet.connectionDecision:
        return [
          Row(
            children: [
              Expanded(
                child: FButton(
                  style: FButtonStyle.outline(),
                  onPress: busy
                      ? null
                      : () => decide(UserPermissionDecision.reject),
                  child: busy ? _busyLabel(loc.deny) : Text(loc.deny),
                ),
              ),
              const SizedBox(width: Spaces.small),
              Expanded(
                child: FButton(
                  style: FButtonStyle.primary(),
                  onPress: busy
                      ? null
                      : () => decide(UserPermissionDecision.accept),
                  child: busy ? _busyLabel(loc.allow) : Text(loc.allow),
                ),
              ),
            ],
          ),
        ];

      case _ActionSet.prefetchDecision:
        return [
          Row(
            children: [
              Expanded(
                child: FButton(
                  style: FButtonStyle.outline(),
                  onPress: busy
                      ? null
                      : () => decide(UserPermissionDecision.reject),
                  child: busy ? _busyLabel(loc.deny) : Text(loc.deny),
                ),
              ),
              const SizedBox(width: Spaces.small),
              Expanded(
                child: FButton(
                  style: FButtonStyle.primary(),
                  onPress: busy
                      ? null
                      : () => decide(UserPermissionDecision.accept),
                  child: busy ? _busyLabel(loc.allow) : Text(loc.allow),
                ),
              ),
            ],
          ),
        ];

      case _ActionSet.permissionDecision:
        return [
          FSwitch(
            label: const Text('Remember my decision'),
            value: _rememberDecision,
            onChange: busy
                ? null
                : (value) {
                    setState(() {
                      _rememberDecision = value;
                    });
                  },
          ),
          const SizedBox(height: Spaces.extraSmall),
          Row(
            children: [
              Expanded(
                child: FButton(
                  style: FButtonStyle.outline(),
                  onPress: busy
                      ? null
                      : () {
                          final decision = _rememberDecision
                              ? UserPermissionDecision.alwaysReject
                              : UserPermissionDecision.reject;
                          decide(decision);
                        },
                  child: busy ? _busyLabel(loc.deny) : Text(loc.deny),
                ),
              ),
              const SizedBox(width: Spaces.small),
              Expanded(
                child: FButton(
                  style: FButtonStyle.primary(),
                  onPress: busy
                      ? null
                      : () {
                          final decision = _rememberDecision
                              ? UserPermissionDecision.alwaysAccept
                              : UserPermissionDecision.accept;
                          decide(decision);
                        },
                  child: busy ? _busyLabel(loc.allow) : Text(loc.allow),
                ),
              ),
            ],
          ),
        ];
    }
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

class _ScrollableWithAffordances extends StatelessWidget {
  const _ScrollableWithAffordances({
    required this.controller,
    required this.child,
    required this.fadeColor,
    required this.padding,
    required this.thumbAlwaysVisible,
    required this.showTopFade,
    required this.showBottomFade,
  });

  final ScrollController controller;
  final Widget child;
  final Color fadeColor;
  final EdgeInsets padding;

  final bool thumbAlwaysVisible;
  final bool showTopFade;
  final bool showBottomFade;

  @override
  Widget build(BuildContext context) {
    const fadeHeight = 22.0;

    return Stack(
      children: [
        Scrollbar(
          controller: controller,
          thumbVisibility: thumbAlwaysVisible,
          child: SingleChildScrollView(
            controller: controller,
            padding: padding,
            child: child,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: fadeHeight,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              opacity: showTopFade ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [fadeColor, fadeColor.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: fadeHeight,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              opacity: showBottomFade ? 1.0 : 0.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [fadeColor.withValues(alpha: 0.0), fadeColor],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
