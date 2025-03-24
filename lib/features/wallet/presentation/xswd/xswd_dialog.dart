import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_providers.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/widgets/components/generic_dialog.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:go_router/go_router.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class XswdDialog extends ConsumerStatefulWidget {
  const XswdDialog({super.key});

  @override
  ConsumerState createState() => _XswdDialogState();
}

class _XswdDialogState extends ConsumerState<XswdDialog> {
  final _decisionFormKey = GlobalKey<FormBuilderState>();

  // 30 seconds
  final int _dialogLifetime = 30000;
  int _millisecondsLeft = 30000;
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
        title = 'Unknown Request';
      case XswdRequestType_Application():
        title = 'Connection Request';
      case XswdRequestType_Permission():
        title = 'Permission Request';
      case XswdRequestType_CancelRequest():
        title = 'Cancel Request';
      case XswdRequestType_AppDisconnect():
        title = 'App Disconnected';
    }

    final isPermissionRequest =
        xswdState.xswdEventSummary?.isPermissionRequest() ?? false;

    final actions = <Widget>[];
    if (isPermissionRequest) {
      actions.add(
        TextButton(
          onPressed: () {
            final decision = xswdState.decision;
            if (decision != null) {
              decision.complete(UserPermissionDecision.reject);
            }
            context.pop();
          },
          child: Text(loc.cancel_button),
        ),
      );
      actions.add(
        TextButton(
          onPressed: () {
            if (_decisionFormKey.currentState!.saveAndValidate()) {
              final decision = xswdState.decision;
              if (decision != null) {
                decision.complete(
                  _decisionFormKey.currentState!.value['decisions_radio_group']
                      as UserPermissionDecision,
                );
              }
              context.pop();
            }
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
          child: Text('Deny'),
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
          child: Text('Allow'),
        ),
      );
    }

    return GenericDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: Spaces.medium,
              top: Spaces.large,
            ),
            child: Text(title, style: context.headlineSmall),
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
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            ),
          ),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.all(Spaces.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID',
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
              'Name',
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
              'Url',
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
              'Description',
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
                'Method',
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.small),
              Text(
                xswdState.permissionRpcRequest?.method ?? '/',
                style: context.bodyLarge,
              ),
              const SizedBox(height: Spaces.medium),
              Text(
                'Params',
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.small),
              Builder(
                builder: (context) {
                  final prettyParams = JsonEncoder.withIndent(
                    '  ',
                  ).convert(xswdState.permissionRpcRequest?.params);
                  return Text(prettyParams, style: context.bodyLarge);
                },
              ),
              const SizedBox(height: Spaces.medium),
              FormBuilder(
                key: _decisionFormKey,
                child: FormBuilderRadioGroup<UserPermissionDecision>(
                  name: 'decisions_radio_group',
                  options: [
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.accept,
                      child: Text('Allow'),
                    ),
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.alwaysAccept,
                      child: Text('Always Allow'),
                    ),
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.reject,
                      child: Text('Deny'),
                    ),
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.alwaysReject,
                      child: Text('Always Deny'),
                    ),
                  ],
                  validator: FormBuilderValidators.required(
                    errorText: loc.field_required_error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: actions,
    );
  }
}
