import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class MySeedDialog extends ConsumerStatefulWidget {
  const MySeedDialog({super.key});

  @override
  ConsumerState<MySeedDialog> createState() => _MySeedDialogState();
}

class _MySeedDialogState extends ConsumerState<MySeedDialog> {
  final _mySeedFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_mySeedFormKey');

  Future<String?>? _pendingGetSeed;

  void _getSeed() {
    if (_mySeedFormKey.currentState?.saveAndValidate() ?? false) {
      final password =
          _mySeedFormKey.currentState?.fields['password']?.value as String;

      final future = ref.read(walletStateProvider.notifier).getSeed(password);

      setState(() {
        _pendingGetSeed = future;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return FutureBuilder(
      future: _pendingGetSeed,
      builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
        // final isErrored = snapshot.hasError &&
        //     snapshot.connectionState != ConnectionState.waiting;
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final isDone = snapshot.connectionState == ConnectionState.done;

        return AlertDialog(
          scrollable: true,
          title: Text(
            loc.my_seed,
            style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Builder(
            builder: (BuildContext context) {
              // var height = context.mediaSize.height;
              var width = context.mediaSize.width;

              return SizedBox(
                width: width,
                child: isWaiting
                    ? const Center(child: CircularProgressIndicator())
                    : isDone
                        ? SelectableText(
                            snapshot.data ?? loc.oups,
                            style: context.bodySmall,
                          )
                        : FormBuilder(
                            key: _mySeedFormKey,
                            child: Column(
                              children: [
                                FormBuilderTextField(
                                  name: 'password',
                                  style: context.bodyLarge,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: loc.password,
                                  ),
                                  validator: FormBuilderValidators.required(),
                                ),
                              ],
                            ),
                          ),
              );
            },
          ),
          actions: [
            if (isDone) ...[
              TextButton(
                onPressed: () => context.pop(),
                child: Text(loc.ok_button),
              ),
            ],
            if (!isWaiting && !isDone) ...[
              TextButton(
                onPressed: () => context.pop(),
                child: Text(loc.cancel_button),
              ),
              TextButton(
                onPressed: _getSeed,
                child: Text(loc.confirm_button),
              ),
            ]
          ],
        );
      },
    );
  }
}
