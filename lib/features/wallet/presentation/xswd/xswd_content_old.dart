import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/burn_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/deploy_contract_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_contract_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/multisig_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transfer_builder_widget.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown_old.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class XSWDContent extends ConsumerStatefulWidget {
  const XSWDContent({super.key});

  @override
  ConsumerState createState() => _XSWDContentState();
}

class _XSWDContentState extends ConsumerState<XSWDContent> {
  final _scrollController = ScrollController();
  final _decisionFormKey = GlobalKey<FormBuilderState>();

  final int _requestLifetime = 60000;
  int _millisecondsLeft = 60000;
  double _progress = 1.0;
  Timer? _timer;
  Timer? _statusCheckTimer;
  bool _isXswdRunning = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkXswdStatus();

    // Check XSWD status periodically
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkXswdStatus();
    });
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

  void _handleTimeout() {
    final xswdState = ref.read(xswdRequestProvider);
    final decision = xswdState.decision;
    if (decision != null && !decision.isCompleted) {
      decision.complete(UserPermissionDecision.reject);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusCheckTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final xswdState = ref.watch(xswdRequestProvider);

    if (xswdState.xswdEventSummary == null) {
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
              'No Active Requests',
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

    final eventType = xswdState.xswdEventSummary!.eventType;
    final isPermissionRequest = xswdState.xswdEventSummary!
        .isPermissionRequest();
    final isApplicationRequest = xswdState.xswdEventSummary!
        .isApplicationRequest();
    final isPrefetchRequest = xswdState.xswdEventSummary!
        .isPrefetchPermissionsRequest();
    final isCancelOrDisconnect =
        xswdState.xswdEventSummary!.isCancelRequest() ||
        xswdState.xswdEventSummary!.isAppDisconnect();

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

    return FadedScroll(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(Spaces.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, title, isCancelOrDisconnect),
            const SizedBox(height: Spaces.large),
            _buildApplicationInfo(context, xswdState),
            if (isPermissionRequest) ...[
              const SizedBox(height: Spaces.large),
              const Divider(),
              const SizedBox(height: Spaces.large),
              _buildPermissionDetails(context, xswdState),
            ],
            if (isPrefetchRequest) ...[
              const SizedBox(height: Spaces.large),
              const Divider(),
              const SizedBox(height: Spaces.large),
              _buildPrefetchDetails(context, xswdState),
            ],
            if (isApplicationRequest) ...[
              const SizedBox(height: Spaces.large),
              const Divider(),
              const SizedBox(height: Spaces.large),
              _buildFuturePermissions(context, xswdState),
            ],
            if (!isCancelOrDisconnect) ...[
              const SizedBox(height: Spaces.extraLarge),
              _buildActions(context, xswdState, isPermissionRequest),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String title,
    bool isCancelOrDisconnect,
  ) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.headlineMedium)),
        if (!isCancelOrDisconnect) ...[
          const SizedBox(width: Spaces.medium),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 3,
                  backgroundColor: context.colors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colors.primary,
                  ),
                ),
              ),
              Text(
                '${(_millisecondsLeft / 1000).ceil()}',
                style: context.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildApplicationInfo(
    BuildContext context,
    XswdRequestState xswdState,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final appInfo = xswdState.xswdEventSummary!.applicationInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection(context, loc.id.capitalize(), appInfo.id),
        const SizedBox(height: Spaces.medium),
        _buildInfoSection(context, loc.name.capitalize(), appInfo.name),
        const SizedBox(height: Spaces.medium),
        _buildInfoSection(context, loc.url.capitalize(), appInfo.url),
        const SizedBox(height: Spaces.medium),
        _buildInfoSection(
          context,
          loc.description.capitalize(),
          appInfo.description,
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.bodyLarge?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.small),
        Text(
          value == null || value.isEmpty ? '/' : value,
          style: context.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPermissionDetails(
    BuildContext context,
    XswdRequestState xswdState,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final request = xswdState.permissionRpcRequest;

    if (request == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${loc.permission_request.capitalize()} ${loc.details.capitalize()}',
          style: context.headlineSmall,
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.method.capitalize(),
          style: context.bodyLarge?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.small),
        Chip(
          label: Text(request.method),
          avatar: const Icon(Icons.code, size: 16),
        ),
        const SizedBox(height: Spaces.medium),
        Text(
          loc.parameters.capitalize(),
          style: context.bodyLarge?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.medium),
        _handlePermissionRpcRequest(request),
      ],
    );
  }

  Widget _buildPrefetchDetails(
    BuildContext context,
    XswdRequestState xswdState,
  ) {
    final loc = ref.read(appLocalizationsProvider);
    final request = xswdState.prefetchPermissionsRequest;

    if (request == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.prefetch_permissions_request.capitalize(),
          style: context.headlineSmall,
        ),
        const SizedBox(height: Spaces.medium),
        if (request.reason != null && request.reason!.isNotEmpty) ...[
          _buildInfoSection(context, 'Reason', request.reason!),
          const SizedBox(height: Spaces.medium),
        ],
        Text(
          '${loc.permissions.capitalize()} Requested',
          style: context.bodyLarge?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.small),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: request.permissions
              .map<Widget>(
                (String permission) => Chip(
                  label: Text(permission),
                  avatar: const Icon(Icons.verified_user, size: 16),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: Spaces.medium),
        Container(
          padding: const EdgeInsets.all(Spaces.medium),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: context.colors.primary, size: 20),
              const SizedBox(width: Spaces.medium),
              Expanded(
                child: Text(
                  'This application is requesting permission to use these features in advance. Approving will allow the app to use these permissions without asking again.',
                  style: context.bodyMedium,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.future_permissions.capitalize(),
          style: context.bodyLarge?.copyWith(
            color: context.theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: Spaces.small),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          children: permissions.keys
              .map<Widget>(
                (String name) => Chip(
                  label: Text(name),
                  avatar: const Icon(Icons.code, size: 16),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActions(
    BuildContext context,
    XswdRequestState xswdState,
    bool isPermissionRequest,
  ) {
    final loc = ref.read(appLocalizationsProvider);

    if (isPermissionRequest) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.action,
            style: context.bodyLarge?.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.small),
          FormBuilder(
            key: _decisionFormKey,
            child: GenericFormBuilderDropdown<UserPermissionDecision>(
              name: 'decisions_dropdown',
              initialValue: UserPermissionDecision.reject,
              items: [
                DropdownMenuItem(
                  value: UserPermissionDecision.reject,
                  child: Text(loc.deny),
                ),
                DropdownMenuItem(
                  value: UserPermissionDecision.alwaysReject,
                  child: Text(loc.always_deny),
                ),
                DropdownMenuItem(
                  value: UserPermissionDecision.accept,
                  child: Text(loc.allow),
                ),
                DropdownMenuItem(
                  value: UserPermissionDecision.alwaysAccept,
                  child: Text(loc.always_allow),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spaces.medium),
          FilledButton(
            onPressed: () => _handleConfirm(xswdState),
            child: Text(loc.confirm_button),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => _handleDeny(xswdState),
          child: Text(loc.deny),
        ),
        const SizedBox(width: Spaces.medium),
        FilledButton(
          onPressed: () => _handleAllow(xswdState),
          child: Text(loc.allow),
        ),
      ],
    );
  }

  void _handleConfirm(XswdRequestState xswdState) {
    final decision = xswdState.decision;
    if (decision != null && !(decision.isCompleted)) {
      if (_decisionFormKey.currentState?.saveAndValidate() ?? false) {
        final selectedDecision =
            _decisionFormKey.currentState!.value['decisions_dropdown']
                as UserPermissionDecision;
        decision.complete(selectedDecision);
        _timer?.cancel();
        ref.read(xswdRequestProvider.notifier).closeSnackBar();
      }
    }
  }

  void _handleDeny(XswdRequestState xswdState) {
    final decision = xswdState.decision;
    if (decision != null && !(decision.isCompleted)) {
      decision.complete(UserPermissionDecision.reject);
      _timer?.cancel();
      ref.read(xswdRequestProvider.notifier).closeSnackBar();
    }
  }

  void _handleAllow(XswdRequestState xswdState) {
    final decision = xswdState.decision;
    if (decision != null && !(decision.isCompleted)) {
      decision.complete(UserPermissionDecision.accept);
      _timer?.cancel();
      ref.read(xswdRequestProvider.notifier).closeSnackBar();
    }
  }

  Widget _handlePermissionRpcRequest(PermissionRpcRequest request) {
    if (request.method == WalletMethod.buildTransaction.jsonKey) {
      final params = BuildTransactionParams.fromJson(request.params!);
      final builder = params.transactionTypeBuilder;

      if (builder is TransfersBuilder) {
        return TransfersBuilderWidget(transfersBuilder: builder);
      } else if (builder is BurnBuilder) {
        return BurnBuilderWidget(burnBuilder: builder);
      } else if (builder is MultisigBuilder) {
        return MultisigBuilderWidget(multisigBuilder: builder);
      } else if (builder is InvokeContractBuilder) {
        return InvokeContractBuilderWidget(invokeContractBuilder: builder);
      } else if (builder is DeployContractBuilder) {
        return DeployContractBuilderWidget(deployContractBuilder: builder);
      }
    }

    return Container(
      padding: const EdgeInsets.all(Spaces.medium),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        const JsonEncoder.withIndent('  ').convert(request.params),
        style: context.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildServerStatus(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spaces.medium,
        vertical: Spaces.small,
      ),
      decoration: BoxDecoration(
        color: _isXswdRunning
            ? context.theme.colors.primaryForeground.withValues(alpha: 0.1)
            : context.theme.colors.destructiveForeground.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isXswdRunning
                  ? context.theme.colors.primary
                  : context.theme.colors.destructive,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Spaces.small),
          Text(
            _isXswdRunning
                ? '${loc.xswd_status}: ${loc.running.capitalize()}'
                : '${loc.xswd_status}: ${loc.stopped.capitalize()}',
            style: context.bodyMedium?.copyWith(
              color: _isXswdRunning
                  ? context.theme.colors.primary
                  : context.theme.colors.destructive,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
