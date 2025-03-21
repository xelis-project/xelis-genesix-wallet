import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_provider.dart';
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
  bool _isPermissionRequest = false;

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
        final decision = ref.read(xswdProvider.select((s) => s.decision));
        if (decision != null) {
          decision.complete(UserPermissionDecision.deny);
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
    final xswdState = ref.watch(xswdProvider);

    String title;
    switch (xswdState.xswdEventSummary?.eventType) {
      case null:
        title = 'Unknown Request';
      case XswdRequestType_Application():
        title = 'Connection Request';
      case XswdRequestType_Permission():
        title = 'Permission Request';
        _isPermissionRequest = true;
      case XswdRequestType_CancelRequest():
        title = 'Cancel Request';
    }

    final actions = <Widget>[];
    if (_isPermissionRequest) {
      actions.add(
        TextButton(
          onPressed: () {
            final decision = xswdState.decision;
            if (decision != null) {
              decision.complete(UserPermissionDecision.deny);
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
              decision.complete(UserPermissionDecision.deny);
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
              decision.complete(UserPermissionDecision.allow);
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
              xswdState.xswdEventSummary?.applicationId ?? '',
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
              xswdState.xswdEventSummary?.applicationName ?? '',
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
              xswdState.xswdEventSummary?.url ?? '',
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
              xswdState.xswdEventSummary?.description ?? '',
              style: context.bodyLarge,
            ),
            if (_isPermissionRequest) ...[
              const SizedBox(height: Spaces.medium),
              Text(
                'Content',
                style: context.bodyLarge!.copyWith(
                  color: context.moreColors.mutedColor,
                ),
              ),
              const SizedBox(height: Spaces.small),
              Text(
                (xswdState.xswdEventSummary?.eventType
                        as XswdRequestType_Permission)
                    .field0,
                style: context.bodyLarge,
              ),
              const SizedBox(height: Spaces.medium),
              FormBuilder(
                key: _decisionFormKey,
                child: FormBuilderRadioGroup<UserPermissionDecision>(
                  name: 'decisions_radio_group',
                  options: [
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.allow,
                      child: Text('Allow'),
                    ),
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.alwaysAllow,
                      child: Text('Always Allow'),
                    ),
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.deny,
                      child: Text('Deny'),
                    ),
                    FormBuilderFieldOption<UserPermissionDecision>(
                      value: UserPermissionDecision.alwaysDeny,
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
