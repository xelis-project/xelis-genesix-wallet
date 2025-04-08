import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/features/wallet/domain/permission_rpc_request.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/burn_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_contract_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/multisig_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transfer_builder_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/shared/widgets/components/generic_form_builder_dropdown.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

import 'components/deploy_contract_builder_widget.dart';

class XswdDialog extends ConsumerStatefulWidget {
  const XswdDialog({super.key});

  @override
  ConsumerState createState() => _XswdDialogState();
}

class _XswdDialogState extends ConsumerState<XswdDialog> {
  final _decisionFormKey = GlobalKey<FormBuilderState>();

  // 60 seconds
  final int _dialogLifetime = 60000;
  int _millisecondsLeft = 60000;
  double _progress = 1.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(Duration(milliseconds: 1), (timer) {
      setState(() {
        _millisecondsLeft--;
        _progress = _millisecondsLeft / _dialogLifetime;
      });

      if (_millisecondsLeft <= 0) {
        _timer.cancel();
        final decision = ref.read(
          xswdRequestProvider.select((s) => s.decision),
        );
        if (decision != null) {
          decision.complete(UserPermissionDecision.reject);
        }
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final xswdState = ref.watch(xswdRequestProvider);

    String title;
    switch (xswdState.xswdEventSummary?.eventType) {
      case null:
        title = loc.unknown_request.capitalize();
      case XswdRequestType_Application():
        title = loc.connection_request.capitalize();
      case XswdRequestType_Permission():
        title = loc.permission_request.capitalize();
      case XswdRequestType_CancelRequest():
        title = loc.cancellation_request.capitalize();
      case XswdRequestType_AppDisconnect():
        title = loc.app_disconnected.capitalize();
    }

    final isApplicationRequest =
        xswdState.xswdEventSummary?.isApplicationRequest() ?? false;

    final isPermissionRequest =
        xswdState.xswdEventSummary?.isPermissionRequest() ?? false;

    final actions = <Widget>[];
    if (isPermissionRequest) {
      actions.add(
        TextButton(
          onPressed: () {
            final decision = xswdState.decision;
            if (decision != null) {
              if (_decisionFormKey.currentState?.saveAndValidate() ?? false) {
                decision.complete(
                  _decisionFormKey.currentState!.value['decisions_dropdown']
                      as UserPermissionDecision,
                );
              }
            }
            context.pop();
          },
          child: Text(loc.confirm_button),
        ),
      );
    } else {
      actions.add(
        TextButton(
          onPressed: () {
            final decision = xswdState.decision;
            if (decision != null) {
              decision.complete(UserPermissionDecision.reject);
            }
            context.pop();
          },
          child: Text(loc.deny),
        ),
      );
      actions.add(
        TextButton(
          onPressed: () {
            final decision = xswdState.decision;
            if (decision != null) {
              decision.complete(UserPermissionDecision.accept);
            }
            context.pop();
          },
          child: Text(loc.allow),
        ),
      );
    }

    return GenericDialog(
      title: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: Spaces.medium,
                  top: Spaces.large,
                ),
                child: Text(
                  title,
                  style: context.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: Spaces.small,
                top: Spaces.small,
              ),
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 3,
                constraints: const BoxConstraints(minWidth: 25, minHeight: 25),
                backgroundColor: context.colors.surface,
                year2023: false,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      content: Container(
        constraints: BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.id.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            Text(
              xswdState.xswdEventSummary?.applicationInfo.id ?? '/',
              style: context.bodyLarge,
            ),
            const SizedBox(height: Spaces.medium),
            Text(
              loc.name.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            Text(
              xswdState.xswdEventSummary?.applicationInfo.name ?? '/',
              style: context.bodyLarge,
            ),
            const SizedBox(height: Spaces.medium),
            Text(
              loc.url.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            Text(
              xswdState.xswdEventSummary?.applicationInfo.url ?? '/',
              style: context.bodyLarge,
            ),
            const SizedBox(height: Spaces.medium),
            Text(
              loc.description.capitalize(),
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
            const SizedBox(height: Spaces.small),
            Text(
              xswdState.xswdEventSummary?.applicationInfo.description ?? '/',
              style: context.bodyLarge,
            ),
            if (isPermissionRequest) ...[
              const SizedBox(height: Spaces.medium),
              Text(
                loc.method.capitalize(),
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.small),
              Builder(
                builder: (context) {
                  final name = xswdState.permissionRpcRequest?.method;
                  if (name != null) {
                    return Chip(
                      label: Text(name),
                      avatar: Icon(Icons.code, size: 16),
                    );
                  } else {
                    return Text('/', style: context.bodyLarge);
                  }
                },
              ),
              const SizedBox(height: Spaces.medium),
              Text(
                loc.action,
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.small),
              Container(
                constraints: BoxConstraints(maxWidth: 200),
                child: FormBuilder(
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
              ),
              const SizedBox(height: Spaces.medium),
              const Divider(),
              _handlePermissionRpcRequest(xswdState.permissionRpcRequest!),
            ],
            if (isApplicationRequest) ...[
              const SizedBox(height: Spaces.medium),
              Text(
                loc.future_permissions.capitalize(),
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.small),
              Wrap(
                spacing: Spaces.small,
                runSpacing: Spaces.extraSmall,
                children:
                    xswdState.xswdEventSummary!.applicationInfo.permissions.keys
                        .map((name) {
                          return Chip(
                            label: Text(name),
                            avatar: Icon(Icons.code, size: 16),
                          );
                        })
                        .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: actions,
    );
  }

  Widget _handlePermissionRpcRequest(PermissionRpcRequest request) {
    if (request.method == WalletMethod.buildTransaction.jsonKey) {
      final params = BuildTransactionParams.fromJson(request.params);
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

    return SelectableText(
      JsonEncoder.withIndent('  ').convert(request.params),
      style: context.bodySmall,
    );
  }
}
