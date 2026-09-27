import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/widgets/components/app_dialog.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_permission_copy.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/burn_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/deploy_contract_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_contract_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/multisig_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transfer_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_json_parameters_view.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_review_text.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class XswdDialog extends ConsumerStatefulWidget {
  const XswdDialog(this.animation, {this.onRequestPresented, super.key});

  final Animation<double> animation;
  final ValueChanged<Object>? onRequestPresented;

  @override
  ConsumerState createState() => _XswdDialogState();
}

enum _ActionSet {
  permissionDecision, // Allow / Always allow / Always deny / Deny
  connectionDecision, // Allow / Deny
  prefetchDecision, // Allow / Deny
}

enum _PermissionDecisionScope { once, connection }

class _XswdDialogState extends ConsumerState<XswdDialog>
    with WidgetsBindingObserver {
  static const Duration _rapidFireWindow = Duration(milliseconds: 500);

  int _millisecondsLeft = 0;
  Timer? _timer;

  Timer? _closeDelayTimer;
  bool _awaitingNextRequest = false;
  Object? _presentedRequestToken;
  Object? _timerRequestToken;

  late final ScrollController _scrollController;

  _PermissionDecisionScope _permissionDecisionScope =
      _PermissionDecisionScope.once;
  Set<String> _selectedPrefetchMethods = const {};
  bool _detailsExpanded = false;

  late final XswdRequest _xswdRequestNotifier;

  @override
  void initState() {
    super.initState();
    _xswdRequestNotifier = ref.read(xswdRequestProvider.notifier);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
  }

  void _setSuppress(bool value, Object token) {
    _xswdRequestNotifier.setSuppressXswdToast(value, token: token);
  }

  void _startTimer(Object token) {
    _timer?.cancel();
    _timerRequestToken = token;
    _millisecondsLeft = _xswdRequestNotifier
        .remainingIfCurrent(token)
        .inMilliseconds;
    // Painting never owns the decision deadline. In particular, opening this
    // dialog late or rebuilding it must not give the request a fresh budget.
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRemaining(token),
    );
    if (_millisecondsLeft == 0) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshRemaining(token),
      );
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _timerRequestToken = null;
  }

  void _refreshRemaining(Object token) {
    if (!mounted || !identical(_timerRequestToken, token)) return;
    if (!_xswdRequestNotifier.isCurrent(token) ||
        _xswdRequestNotifier.checkExpiry(token)) {
      _stopTimer();
      return;
    }
    setState(
      () => _millisecondsLeft = _xswdRequestNotifier
          .remainingIfCurrent(token)
          .inMilliseconds,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final token = _timerRequestToken;
    if (token != null) _refreshRemaining(token);
  }

  void _cancelRapidFireWait(Object token) {
    _closeDelayTimer?.cancel();
    _closeDelayTimer = null;

    _setSuppress(false, token);

    _awaitingNextRequest = false;
  }

  void _beginRapidFireWait(Object token) {
    _closeDelayTimer?.cancel();

    _setSuppress(true, token);

    setState(() {
      _awaitingNextRequest = true;
    });

    _closeDelayTimer = Timer(_rapidFireWindow, () {
      if (!mounted) return;

      if (!_xswdRequestNotifier.isCurrent(token)) {
        setState(() {
          _awaitingNextRequest = false;
        });
        return;
      }

      _setSuppress(false, token);
      _xswdRequestNotifier.clearIfCurrent(token);
      if (identical(_presentedRequestToken, token)) {
        context.pop();
      }
    });
  }

  _ActionSet _computeActionSet(XswdRequestState xswdState) {
    final summary = xswdState.xswdEventSummary;
    if (summary == null) return _ActionSet.connectionDecision;
    if (summary.isPermissionRequest) return _ActionSet.permissionDecision;
    if (summary.isApplicationRequest) return _ActionSet.connectionDecision;
    if (summary.isPrefetchPermissionsRequest) {
      return _ActionSet.prefetchDecision;
    }

    return _ActionSet.connectionDecision;
  }

  void _syncTimerWithState() {
    if (_awaitingNextRequest || !ref.read(xswdRequestProvider).pending) {
      _stopTimer();
      return;
    }
    final token = _presentedRequestToken;
    if (token != null && !identical(_timerRequestToken, token)) {
      _startTimer(token);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeDelayTimer?.cancel();
    _timer?.cancel();
    final token = _presentedRequestToken;
    if (token != null) {
      final notifier = _xswdRequestNotifier;
      Future<void>.microtask(
        () => notifier.setSuppressXswdToast(false, token: token),
      );
    }

    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final xswdState = ref.watch(xswdRequestProvider);
    // A popped route can still rebuild during its exit animation. It must not
    // present or acknowledge a successor that belongs to the next dialog.
    if (ModalRoute.of(context)?.isActive == false) {
      return const SizedBox.shrink();
    }
    final token = xswdState.token;

    if (xswdState.xswdEventSummary == null || token == null) {
      final presentedToken = _presentedRequestToken;
      if (presentedToken != null) {
        _resetPresentation(presentedToken, nextToken: null);
      }

      return AppDialog(
        clipBehavior: Clip.antiAlias,
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
              if (mounted && ref.read(xswdRequestProvider).token == null) {
                context.pop();
              }
            },
            child: Text(loc.close),
          ),
        ],
      );
    }

    final summary = xswdState.xswdEventSummary!;
    final transactionReview =
        xswdState.permissionReview?.isBuildTransaction == true
        ? xswdState.permissionReview
        : null;

    if (!identical(_presentedRequestToken, token)) {
      final previousToken = _presentedRequestToken;
      if (previousToken != null) {
        _resetPresentation(previousToken, nextToken: token);
      }
      _presentedRequestToken = token;
      _selectedPrefetchMethods = _initialPrefetchSelection(xswdState);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            ModalRoute.of(context)?.isActive == false ||
            !identical(_presentedRequestToken, token) ||
            !_xswdRequestNotifier.isCurrent(token)) {
          return;
        }
        widget.onRequestPresented?.call(token);
        _setSuppress(false, token);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }

    final actionSet = _computeActionSet(xswdState);
    _syncTimerWithState();

    final eventType = summary.kind;

    String title;
    switch (eventType) {
      case XelisXswdRequestKind.application:
        title = loc.connection_request.capitalize();
      case XelisXswdRequestKind.permission:
        title = transactionReview != null
            ? loc.xswd_transaction_review_title
            : loc.permission_request.capitalize();
      case XelisXswdRequestKind.prefetchPermissions:
        title = loc.xswd_requested_permissions;
      case XelisXswdRequestKind.cancel:
        title = loc.unknown_request.capitalize();
      case XelisXswdRequestKind.applicationDisconnect:
        title = loc.unknown_request.capitalize();
    }

    final compact =
        MediaQuery.sizeOf(context).width < context.theme.breakpoints.sm;
    return AppDialog(
      clipBehavior: Clip.antiAlias,
      animation: widget.animation,
      style: compact
          ? const .delta(insetPadding: .value(EdgeInsets.all(8)))
          : const .context(),
      constraints: const BoxConstraints(maxWidth: 700),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxBodyHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 620.0;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: Column(
              mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.all(Spaces.extraSmall),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(title, style: context.headlineSmall),
                        ),
                        const SizedBox(width: Spaces.medium),
                        FTooltip(
                          tipBuilder: (context, controller) => Text(loc.close),
                          child: FButton.icon(
                            variant: .ghost,
                            semanticsTooltip: loc.close,
                            onPress: () => _rejectAndClose(token),
                            child: const Icon(FLucideIcons.x, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: _XswdCountdownIndicator(
                        awaitingNextRequest: _awaitingNextRequest,
                        millisecondsLeft: _millisecondsLeft,
                        loc: loc,
                      ),
                    ),
                    if (compact)
                      FButton.icon(
                        variant: .ghost,
                        semanticsTooltip: loc.close,
                        onPress: () => _rejectAndClose(token),
                        child: const Icon(FLucideIcons.x, size: 22),
                      ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: Spaces.small),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spaces.small,
                    ),
                    child: _XswdApplicationInfoSection(
                      appInfo: summary.application,
                      loc: loc,
                    ),
                  ),
                  const SizedBox(height: Spaces.medium),
                ],
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
                          if (compact) ...[
                            Text(title, style: context.headlineSmall),
                            const SizedBox(height: Spaces.small),
                            _XswdApplicationInfoSection(
                              appInfo: summary.application,
                              loc: loc,
                            ),
                            const SizedBox(height: Spaces.medium),
                          ],
                          if (transactionReview != null) ...[
                            _XswdTransactionReviewSection(
                              review: transactionReview,
                              loc: loc,
                            ),
                            const SizedBox(height: Spaces.medium),
                          ],
                          if (transactionReview == null)
                            if (xswdState.permissionReview
                                case final review?) ...[
                              _XswdPermissionImpactSection(
                                review: review,
                                loc: loc,
                                forConnection:
                                    _permissionDecisionScope ==
                                    _PermissionDecisionScope.connection,
                              ),
                              const SizedBox(height: Spaces.medium),
                            ],
                          if (xswdState.prefetchPermissionsRequest
                              case final prefetchRequest?) ...[
                            _XswdMinimalPrefetchDetailsSection(
                              key: ValueKey(token),
                              request: prefetchRequest,
                              currentPermissions:
                                  xswdState.prefetchCurrentPermissions,
                              selectedMethods: _selectedPrefetchMethods,
                              loc: loc,
                              onSelectionChanged: (methods) {
                                if (!_xswdRequestNotifier.isCurrent(token)) {
                                  return;
                                }
                                setState(() {
                                  _selectedPrefetchMethods = methods;
                                });
                              },
                            ),
                            const SizedBox(height: Spaces.medium),
                          ],
                          _XswdMoreDetailsAccordion(
                            expanded: _detailsExpanded,
                            appInfo: summary.application,
                            prefetchRequest:
                                xswdState.prefetchPermissionsRequest,
                            permissionReview: transactionReview == null
                                ? xswdState.permissionReview
                                : null,
                            loc: loc,
                            onExpandedChange: (expanded) {
                              setState(() {
                                _detailsExpanded = expanded;
                              });
                            },
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
      actions: actionSet == _ActionSet.prefetchDecision
          ? _buildPrefetchDecisionActions(
              busy: _awaitingNextRequest,
              selectionCount: _selectedPrefetchMethods.length,
              loc: loc,
              onContinue: () => _handlePrefetchDecision(
                token: token,
                xswdState: xswdState,
                permissions: const {},
              ),
              onAllow: () => _handlePrefetchDecision(
                token: token,
                xswdState: xswdState,
                permissions: _selectedPrefetchMethods,
              ),
            )
          : _XswdActionFactory(
              requestToken: token,
              actionSet: actionSet,
              busy: _awaitingNextRequest,
              permissionDecisionScope: _permissionDecisionScope,
              canPersistPermission:
                  xswdState.permissionReview?.canPersist ?? true,
              loc: loc,
              onPermissionDecisionScopeChanged: (scope) {
                setState(() {
                  _permissionDecisionScope = scope;
                });
              },
              onDecision: (decision) => _handleDecision(
                token: token,
                xswdState: xswdState,
                decision: decision,
              ),
            ).build(context),
    );
  }

  void _resetPresentation(Object previousToken, {required Object? nextToken}) {
    _closeDelayTimer?.cancel();
    _closeDelayTimer = null;
    _stopTimer();
    _awaitingNextRequest = false;
    _millisecondsLeft = 0;
    _permissionDecisionScope = _PermissionDecisionScope.once;
    _selectedPrefetchMethods = const {};
    _detailsExpanded = false;
    _setSuppress(false, previousToken);
    _presentedRequestToken = nextToken;
  }

  void _rejectAndClose(Object token) {
    if (!_xswdRequestNotifier.isCurrent(token)) return;
    _stopTimer();
    _cancelRapidFireWait(token);
    if (_xswdRequestNotifier.rejectIfCurrent(token) &&
        mounted &&
        identical(_presentedRequestToken, token)) {
      context.pop();
    }
  }

  void _showAssetDetails(
    BuildContext context,
    AppLocalizations loc,
    String asset,
  ) {
    showAppDialog<void>(
      context: context,
      builder: (context, style, animation) => AppDialog(
        clipBehavior: Clip.antiAlias,
        style: style,
        animation: animation,
        direction: Axis.horizontal,
        title: Row(
          children: [
            const Icon(FLucideIcons.coins),
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

  void _handleDecision({
    required Object token,
    required XswdRequestState xswdState,
    required XelisXswdDecision decision,
  }) {
    if (!_xswdRequestNotifier.isCurrent(token) || !xswdState.pending) return;
    _stopTimer();

    final rejected =
        decision == XelisXswdDecision.reject ||
        decision == XelisXswdDecision.alwaysReject;
    if (rejected) {
      if (!_xswdRequestNotifier.resolveIfCurrent(token, decision)) return;
      _cancelRapidFireWait(token);
      _xswdRequestNotifier.clearIfCurrent(token);
      if (mounted && identical(_presentedRequestToken, token)) {
        context.pop();
      }
      return;
    }

    if (_xswdRequestNotifier.resolveIfCurrent(token, decision)) {
      _showAcceptedConnectionToast(xswdState, decision);
      _beginRapidFireWait(token);
    }
  }

  void _handlePrefetchDecision({
    required Object token,
    required XswdRequestState xswdState,
    required Iterable<String> permissions,
  }) {
    if (!_xswdRequestNotifier.isCurrent(token) || !xswdState.pending) return;
    _stopTimer();
    if (_xswdRequestNotifier.resolvePrefetchIfCurrent(token, permissions)) {
      _beginRapidFireWait(token);
    }
  }

  void _showAcceptedConnectionToast(
    XswdRequestState xswdState,
    XelisXswdDecision decision,
  ) {
    final summary = xswdState.xswdEventSummary;
    if (summary == null || !summary.isApplicationRequest) {
      return;
    }

    final accepted =
        decision == XelisXswdDecision.accept ||
        decision == XelisXswdDecision.alwaysAccept;
    if (!accepted) {
      return;
    }

    final loc = ref.read(appLocalizationsProvider);
    ref
        .read(toastProvider.notifier)
        .showInformation(
          title: loc.xswd_connection_approved(summary.application.name),
        );
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

class _XswdPermissionImpactSection extends StatelessWidget {
  const _XswdPermissionImpactSection({
    required this.review,
    required this.loc,
    required this.forConnection,
  });

  final XswdPermissionReview review;
  final AppLocalizations loc;
  final bool forConnection;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('xswd-permission-impact'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          xswdPermissionActionLabel(review.method, loc),
          style: context.titleMedium,
        ),
        const SizedBox(height: Spaces.extraSmall),
        if (review.subscriptionEvent case final event?)
          Text(loc.xswd_recent_event(xswdWalletEventLabel(event, loc))),
        if (_consentNote case final note?) Text(note),
        if (review.policy.canPersist) ...[
          const SizedBox(height: Spaces.small),
          Text(
            forConnection
                ? loc.xswd_scope_connection_description
                : loc.xswd_scope_once_description,
          ),
        ],
      ],
    );
  }

  String? get _consentNote {
    if (review.subscriptionEvent != null && !forConnection) {
      return review.method == 'subscribe'
          ? loc.xswd_subscription_once_notice
          : null;
    }
    return xswdPermissionConsentNote(review.method, loc) ??
        (review.policy.effect == XswdMethodEffect.appStorage
            ? xswdPermissionCopy(review.method, review.policy, loc).description
            : null);
  }
}

class _XswdApplicationInfoSection extends StatelessWidget {
  const _XswdApplicationInfoSection({required this.appInfo, required this.loc});

  final XelisXswdApplication appInfo;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final url = appInfo.url?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appInfo.name,
          style: context.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (url != null && url.isNotEmpty)
          Text(
            '${loc.xswd_declared_origin}: $url',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.bodySmall?.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
      ],
    );
  }
}

class _XswdTransactionReviewSection extends StatelessWidget {
  const _XswdTransactionReviewSection({
    required this.review,
    required this.loc,
  });

  final XswdPermissionReview review;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final params = review.buildTransactionParams!;
    final feeValue = _formatXswdFee(params.fee, loc);
    final baseFeeValue = _formatXswdBaseFee(params.baseFee, loc);
    final hasBroadInterContractAuthority = _hasBroadInterContractAuthority(
      params.transactionTypeBuilder,
    );

    return Column(
      key: const ValueKey('xswd-transaction-review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FAlert(
          key: const ValueKey('xswd-transaction-security-warning'),
          icon: const Icon(FLucideIcons.triangleAlert),
          title: Text(loc.xswd_transaction_review_title),
          subtitle: Text(loc.xswd_transaction_review_warning),
        ),
        if (hasBroadInterContractAuthority) ...[
          const SizedBox(height: Spaces.medium),
          FAlert(
            key: const ValueKey('xswd-inter-contract-broad-warning'),
            icon: const Icon(FLucideIcons.triangleAlert),
            title: Text(loc.warning),
            subtitle: Text(loc.xswd_inter_contract_broad_warning),
          ),
        ],
        const SizedBox(height: Spaces.medium),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: [_XswdMinimalBadge(label: review.request.method)],
        ),
        const SizedBox(height: Spaces.small),
        _XswdPermissionPayload(review: review, loc: loc, onAssetTap: (_) {}),
        const SizedBox(height: Spaces.small),
        _PermissionContentContainer(
          maxHeight: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _XswdInfoRow(label: loc.fee, value: feeValue),
              const SizedBox(height: Spaces.small),
              _XswdInfoRow(label: loc.xswd_base_fee, value: baseFeeValue),
              if (params.feeLimit case final feeLimit?) ...[
                const SizedBox(height: Spaces.small),
                _XswdInfoRow(
                  label: loc.fee_limit,
                  value: _formatXswdAtomicUnits(feeLimit, loc),
                ),
              ],
              if (params.nonce case final nonce?) ...[
                const SizedBox(height: Spaces.small),
                _XswdInfoRow(
                  label: loc.xswd_transaction_nonce,
                  value: nonce.toString(),
                ),
              ],
              if (params.txVersion case final version?) ...[
                const SizedBox(height: Spaces.small),
                _XswdInfoRow(
                  label: loc.xswd_transaction_version,
                  value: version.toString(),
                ),
              ],
              const SizedBox(height: Spaces.small),
              _XswdInfoRow(
                label: loc.broadcast,
                value: params.broadcast ? loc.enabled : loc.disabled,
              ),
              const SizedBox(height: Spaces.small),
              _XswdInfoRow(
                label: loc.xswd_response_as_hex,
                value: params.txAsHex ? loc.enabled : loc.disabled,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _hasBroadInterContractAuthority(TransactionTypeBuilder builder) {
  if (builder is! InvokeContractBuilder) return false;
  return switch (builder.permission) {
    AllInterContractPermission() ||
    ExcludedInterContractPermission() ||
    UnknownInterContractPermission() => true,
    NoInterContractPermission() || SpecificInterContractPermission() => false,
  };
}

String _formatXswdFee(FeeBuilder fee, AppLocalizations loc) {
  return switch (fee) {
    FixedFeeBuilder(:final amount) => _formatXswdAtomicUnits(amount, loc),
    ExtraFeeBuilder(:final mode) => switch (mode) {
      NoExtraFee() => loc.xswd_fee_automatic,
      TipExtraFee(:final amount) =>
        '${loc.xswd_fee_automatic} + ${_formatXswdAtomicUnits(amount, loc)}',
      MultiplierExtraFee(:final multiplier) => loc.xswd_fee_multiplier(
        multiplier,
      ),
    },
  };
}

String _formatXswdBaseFee(BaseFeeMode fee, AppLocalizations loc) {
  return switch (fee) {
    NoBaseFee() => loc.xswd_fee_automatic,
    FixedBaseFee(:final amount) => _formatXswdAtomicUnits(amount, loc),
    CappedBaseFee(:final amount) => '≤ ${_formatXswdAtomicUnits(amount, loc)}',
  };
}

String _formatXswdAtomicUnits(BigInt amount, AppLocalizations loc) {
  return loc.xswd_fee_atomic_units(
    formatBigInt(amount, locale: loc.localeName),
  );
}

class _XswdMoreDetailsAccordion extends StatelessWidget {
  const _XswdMoreDetailsAccordion({
    required this.expanded,
    required this.appInfo,
    required this.prefetchRequest,
    required this.permissionReview,
    required this.loc,
    required this.onExpandedChange,
    required this.onAssetTap,
  });

  final bool expanded;
  final XelisXswdApplication appInfo;
  final XelisXswdPrefetchPermissionsRequest? prefetchRequest;
  final XswdPermissionReview? permissionReview;
  final AppLocalizations loc;
  final ValueChanged<bool> onExpandedChange;
  final ValueChanged<String> onAssetTap;

  @override
  Widget build(BuildContext context) {
    final hasDescription = appInfo.description.isNotEmpty;
    final hasOrigin = appInfo.url?.isNotEmpty == true;
    final hasPermissionDetails = permissionReview != null;

    return FAccordion(
      control: FAccordionControl.lifted(
        expanded: (index) => index == 0 && expanded,
        onChange: (index, nextExpanded) {
          if (index == 0) {
            onExpandedChange(nextExpanded);
          }
        },
      ),
      children: [
        FAccordionItem(
          title: Text(loc.more_details),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appInfo.url case final url? when url.isNotEmpty) ...[
                const SizedBox(height: Spaces.small),
                _XswdInfoRow(label: loc.xswd_declared_origin, value: url),
              ],
              if (hasDescription) ...[
                if (hasOrigin) const SizedBox(height: Spaces.medium),
                _XswdInfoRow(
                  label: loc.description.capitalize(),
                  value: appInfo.description,
                ),
              ],
              if (hasPermissionDetails) ...[
                if (hasDescription || hasOrigin)
                  const SizedBox(height: Spaces.medium),
                _XswdMinimalPermissionSection(
                  review: permissionReview!,
                  loc: loc,
                  onAssetTap: onAssetTap,
                ),
              ],
              if (prefetchRequest case final prefetch?) ...[
                if (prefetch.reason case final reason?
                    when reason.isNotEmpty) ...[
                  const SizedBox(height: Spaces.medium),
                  XswdReviewText(label: loc.reason, value: reason, loc: loc),
                ],
                for (final method in prefetch.permissions) ...[
                  const SizedBox(height: Spaces.medium),
                  _XswdPermissionExplanation(method: method, loc: loc),
                ],
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
    required this.review,
    required this.loc,
    required this.onAssetTap,
  });

  final XswdPermissionReview review;
  final AppLocalizations loc;
  final ValueChanged<String> onAssetTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    final hasParams = review.parameters?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _XswdPermissionExplanation(method: review.method, loc: loc),
        if (hasParams) ...[
          const SizedBox(height: Spaces.small),
          Text(
            loc.details.capitalize(),
            style: context.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: Spaces.extraSmall),
          _XswdPermissionPayload(
            review: review,
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
    super.key,
    required this.request,
    required this.currentPermissions,
    required this.selectedMethods,
    required this.loc,
    required this.onSelectionChanged,
  });

  final XelisXswdPrefetchPermissionsRequest request;
  final Map<String, XelisXswdPermissionPolicy> currentPermissions;
  final Set<String> selectedMethods;
  final AppLocalizations loc;
  final ValueChanged<Set<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final selectable = <XswdMethodEffect, List<String>>{};
    final fixed = <String>[];
    final allowed = <String>[];
    for (final method in request.permissions) {
      final policy = tryXswdMethodPolicyForKey(method);
      final current =
          currentPermissions[method] ?? XelisXswdPermissionPolicy.ask;
      if (policy?.canPrefetch == true) {
        if (current == XelisXswdPermissionPolicy.accept) {
          allowed.add(method);
        } else {
          selectable
              .putIfAbsent(
                xswdPermissionPresentationEffect(policy!.effect),
                () => [],
              )
              .add(method);
        }
      } else {
        fixed.add(method);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.xswd_permissions_connection_scope),
        if (request.permissions.any(xswdIsEventMethod)) ...[
          const SizedBox(height: Spaces.extraSmall),
          Text(loc.xswd_event_permissions_notice),
        ],
        for (final group in selectable.entries) ...[
          const SizedBox(height: Spaces.medium),
          FSelectGroup<String>(
            key: ValueKey('xswd-prefetch-${group.key.name}'),
            label: Text(xswdPermissionEffectTitle(group.key, loc)),
            control: .managed(
              initial: selectedMethods.intersection(group.value.toSet()),
              onChange: (values) {
                final next = {...selectedMethods}..removeAll(group.value);
                next.addAll(values);
                onSelectionChanged(Set.unmodifiable(next));
              },
            ),
            children: [
              for (final method in group.value)
                .checkbox(
                  value: method,
                  label: Text(xswdPermissionActionLabel(method, loc)),
                  description:
                      xswdPermissionConsentNote(method, loc) == null &&
                          currentPermissions[method] !=
                              XelisXswdPermissionPolicy.reject
                      ? null
                      : _XswdConsentNote(
                          note: xswdPermissionConsentNote(method, loc),
                          blocked:
                              currentPermissions[method] ==
                              XelisXswdPermissionPolicy.reject,
                          loc: loc,
                        ),
                  semanticsLabel: xswdPermissionActionLabel(method, loc),
                ),
            ],
          ),
        ],
        if (allowed.isNotEmpty) ...[
          const SizedBox(height: Spaces.medium),
          FAccordion(
            children: [
              FAccordionItem(
                title: Text(
                  loc.xswd_prefetch_already_allowed_count(allowed.length),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final method in allowed)
                      Text(xswdPermissionActionLabel(method, loc)),
                  ],
                ),
              ),
            ],
          ),
        ],
        for (final method in fixed) ...[
          const SizedBox(height: Spaces.medium),
          _XswdPrefetchFixedPermissionRule(
            method: method,
            currentPolicy: currentPermissions[method],
            loc: loc,
          ),
        ],
      ],
    );
  }
}

class _XswdPrefetchFixedPermissionRule extends StatelessWidget {
  const _XswdPrefetchFixedPermissionRule({
    required this.method,
    required this.currentPolicy,
    required this.loc,
  });

  final String method;
  final XelisXswdPermissionPolicy? currentPolicy;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final policy = tryXswdMethodPolicyForKey(method);
    final copy = xswdPermissionCopy(method, policy, loc);
    final label = switch ((policy, currentPolicy)) {
      (final value?, _) when !value.isSupported =>
        loc.xswd_permission_status_unsupported,
      (_, XelisXswdPermissionPolicy.reject) =>
        loc.xswd_permission_status_blocked,
      (final value?, _) when value.isSupported =>
        loc.xswd_transaction_each_time,
      _ => loc.xswd_permission_status_unsupported,
    };
    return Text(
      policy?.isSupported == true &&
              currentPolicy != XelisXswdPermissionPolicy.reject
          ? label
          : '${copy.title} — $label',
    );
  }
}

class _XswdConsentNote extends StatelessWidget {
  const _XswdConsentNote({
    required this.note,
    required this.blocked,
    required this.loc,
  });

  final String? note;
  final bool blocked;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note case final value?) Text(value),
        if (blocked) Text(loc.xswd_prefetch_previously_blocked),
      ],
    );
  }
}

class _XswdPermissionExplanation extends StatelessWidget {
  const _XswdPermissionExplanation({required this.method, required this.loc});

  final String method;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.colors.mutedForeground;
    final copy = xswdPermissionCopy(
      method,
      tryXswdMethodPolicyForKey(method),
      loc,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.title, style: context.titleSmall),
        Text(copy.description),
        SelectableText(
          method,
          style: context.bodySmall?.copyWith(
            color: muted,
            fontFamily: 'monospace',
          ),
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
    required this.review,
    required this.loc,
    required this.onAssetTap,
  });

  final XswdPermissionReview review;
  final AppLocalizations loc;
  final ValueChanged<String> onAssetTap;

  @override
  Widget build(BuildContext context) {
    final parameters = review.parameters;
    Widget? builderWidget;

    if (parameters == null || parameters.isEmpty) {
      return const SizedBox.shrink();
    }

    if (review.isBuildTransaction) {
      final params = review.buildTransactionParams!;
      final builder = params.transactionTypeBuilder;

      if (builder is TransfersBuilder) {
        builderWidget = TransfersBuilderWidget(
          transfersBuilder: builder,
          destinationDescriptors: review.transferDestinations,
        );
      } else if (builder is BurnBuilder) {
        builderWidget = BurnBuilderWidget(burnBuilder: builder);
      } else if (builder is MultisigBuilder) {
        builderWidget = MultisigBuilderWidget(multisigBuilder: builder);
      } else if (builder is InvokeContractBuilder) {
        builderWidget = InvokeContractBuilderWidget(
          invokeContractBuilder: builder,
          parsedParameters: review.parsedInvokeParameters,
        );
      } else if (builder is DeployContractBuilder) {
        builderWidget = DeployContractBuilderWidget(
          deployContractBuilder: builder,
        );
      }
    } else if (parameters.length == 1 &&
        parameters.containsKey('asset') &&
        parameters['asset'] is String) {
      final asset = parameters['asset'] as String;
      builderWidget = Wrap(
        spacing: Spaces.small,
        runSpacing: Spaces.small,
        children: [
          _AssetPermissionBadge(
            asset: asset,
            assetLabel: loc.asset,
            actionLabel: loc.more_details,
            onTap: () => onAssetTap(asset),
          ),
        ],
      );
    }

    if (review.isBuildTransaction && builderWidget == null) {
      return const SizedBox.shrink();
    }

    final Widget content =
        builderWidget ??
        XswdJsonParametersView(parameters: parameters, loc: loc);

    return _PermissionContentContainer(
      key: const ValueKey('xswd-permission-payload-container'),
      child: SingleChildScrollView(child: content),
    );
  }
}

class _XswdActionFactory {
  const _XswdActionFactory({
    required this.requestToken,
    required this.actionSet,
    required this.busy,
    required this.permissionDecisionScope,
    required this.canPersistPermission,
    required this.loc,
    required this.onPermissionDecisionScopeChanged,
    required this.onDecision,
  });

  final Object requestToken;
  final _ActionSet actionSet;
  final bool busy;
  final _PermissionDecisionScope permissionDecisionScope;
  final bool canPersistPermission;
  final AppLocalizations loc;
  final ValueChanged<_PermissionDecisionScope> onPermissionDecisionScopeChanged;
  final ValueChanged<XelisXswdDecision> onDecision;

  List<Widget> build(BuildContext context) {
    switch (actionSet) {
      case _ActionSet.connectionDecision:
        return _buildBinaryDecisionActions(
          context: context,
          busy: busy,
          denyLabel: loc.deny,
          allowLabel: loc.allow,
          onDeny: () => onDecision(XelisXswdDecision.reject),
          onAllow: () => onDecision(XelisXswdDecision.accept),
        );

      case _ActionSet.prefetchDecision:
        return const [];

      case _ActionSet.permissionDecision:
        if (!canPersistPermission) {
          return _buildBinaryDecisionActions(
            context: context,
            busy: busy,
            denyLabel: loc.xswd_deny_once,
            allowLabel: loc.xswd_allow_once,
            onDeny: () => onDecision(XelisXswdDecision.reject),
            onAllow: () => onDecision(XelisXswdDecision.accept),
          );
        }
        final forConnection =
            permissionDecisionScope == _PermissionDecisionScope.connection;
        return [
          FSelectGroup<_PermissionDecisionScope>(
            key: ValueKey(requestToken),
            enabled: !busy,
            label: Text(loc.xswd_decision_scope),
            control: .managedRadio(
              initial: permissionDecisionScope,
              onChange: (values) {
                if (values.length == 1) {
                  onPermissionDecisionScopeChanged(values.single);
                }
              },
            ),
            children: [
              .radio(
                value: _PermissionDecisionScope.once,
                label: Text(loc.xswd_scope_once),
              ),
              .radio(
                value: _PermissionDecisionScope.connection,
                label: Text(loc.xswd_scope_connection),
              ),
            ],
          ),
          const SizedBox(height: Spaces.extraSmall),
          ..._buildBinaryDecisionActions(
            context: context,
            busy: busy,
            denyLabel: forConnection
                ? loc.xswd_block_for_connection
                : loc.xswd_deny_once,
            allowLabel: forConnection
                ? loc.xswd_allow_for_connection
                : loc.xswd_allow_once,
            onDeny: () {
              final decision = forConnection
                  ? XelisXswdDecision.alwaysReject
                  : XelisXswdDecision.reject;
              onDecision(decision);
            },
            onAllow: () {
              final decision = forConnection
                  ? XelisXswdDecision.alwaysAccept
                  : XelisXswdDecision.accept;
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
      LayoutBuilder(
        builder: (context, constraints) {
          final stackActions =
              constraints.maxWidth < 360 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          final denyButton = _XswdDecisionButton(
            busy: busy,
            label: denyLabel,
            variant: .outline,
            onPress: onDeny,
          );
          final allowButton = _XswdDecisionButton(
            busy: busy,
            label: allowLabel,
            onPress: onAllow,
          );
          if (stackActions) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                denyButton,
                const SizedBox(height: Spaces.small),
                allowButton,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: denyButton),
              const SizedBox(width: Spaces.small),
              Expanded(child: allowButton),
            ],
          );
        },
      ),
    ];
  }
}

Set<String> _initialPrefetchSelection(XswdRequestState state) {
  final request = state.prefetchPermissionsRequest;
  if (request == null) return const {};
  return Set.unmodifiable(
    request.permissions.where((method) {
      final policy = tryXswdMethodPolicyForKey(method);
      final current =
          state.prefetchCurrentPermissions[method] ??
          XelisXswdPermissionPolicy.ask;
      return policy?.canPrefetch == true &&
          current == XelisXswdPermissionPolicy.ask;
    }),
  );
}

List<Widget> _buildPrefetchDecisionActions({
  required bool busy,
  required int selectionCount,
  required AppLocalizations loc,
  required VoidCallback onContinue,
  required VoidCallback onAllow,
}) {
  return [
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _XswdDecisionButton(
          busy: busy,
          label: loc.xswd_prefetch_continue_without_new_permissions,
          variant: .outline,
          onPress: onContinue,
        ),
        const SizedBox(height: Spaces.small),
        _XswdDecisionButton(
          busy: busy,
          label: loc.xswd_prefetch_allow_count(selectionCount),
          onPress: selectionCount > 0 ? onAllow : null,
        ),
      ],
    ),
  ];
}

class _XswdDecisionButton extends StatelessWidget {
  const _XswdDecisionButton({
    required this.busy,
    required this.label,
    this.variant = FButtonVariant.primary,
    required this.onPress,
  });

  final bool busy;
  final String label;
  final FButtonVariant variant;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: variant,
      onPress: busy ? null : onPress,
      child: Flexible(child: Text(label, textAlign: TextAlign.center)),
    );
  }
}

class _XswdCountdownIndicator extends StatelessWidget {
  const _XswdCountdownIndicator({
    required this.awaitingNextRequest,
    required this.millisecondsLeft,
    required this.loc,
  });

  final bool awaitingNextRequest;
  final int millisecondsLeft;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final secondsLeft = millisecondsLeft <= 0
        ? 0
        : (millisecondsLeft + 999) ~/ 1000;
    final time =
        '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}';
    final urgent = !awaitingNextRequest && secondsLeft <= 30;
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // The live-region label changes once, not at every timer tick.
          Semantics(
            liveRegion: true,
            label: urgent ? loc.xswd_expiring_soon : '',
            child: const SizedBox.shrink(),
          ),
          Text(
            awaitingNextRequest ? loc.loading : loc.xswd_expires_in(time),
            style: context.bodySmall?.copyWith(
              color: urgent ? colors.destructive : colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _XswdIconBadge extends StatelessWidget {
  const _XswdIconBadge({
    this.variant = FBadgeVariant.primary,
    required this.icon,
    required this.child,
  });

  final FBadgeVariant variant;
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
    required this.actionLabel,
    required this.onTap,
  });

  final String asset;
  final String assetLabel;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final truncated = asset.length > 16
        ? '${asset.substring(0, 8)}...${asset.substring(asset.length - 6)}'
        : asset;

    return FTappable(
      semanticsTooltip: actionLabel,
      onPress: onTap,
      builder: (context, states, child) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              states.contains(FTappableVariant.hovered) ||
                  states.contains(FTappableVariant.pressed)
              ? context.theme.colors.secondary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
      child: _XswdIconBadge(
        variant: .outline,
        icon: FLucideIcons.coins,
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
                FLucideIcons.circleQuestionMark,
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
  const _PermissionContentContainer({
    required this.child,
    this.maxHeight = 300,
    super.key,
  });

  final Widget child;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxHeight == null
          ? null
          : BoxConstraints(maxHeight: maxHeight!),
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
