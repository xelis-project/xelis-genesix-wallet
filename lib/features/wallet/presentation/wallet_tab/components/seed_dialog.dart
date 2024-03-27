import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/wallet_tab/components/seed_content_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';

class MySeedDialog extends ConsumerStatefulWidget {
  const MySeedDialog({super.key});

  @override
  ConsumerState<MySeedDialog> createState() => _MySeedDialogState();
}

class _MySeedDialogState extends ConsumerState<MySeedDialog> {
  final _mySeedFormKey =
      GlobalKey<FormBuilderState>(debugLabel: '_mySeedFormKey');
  late Widget _seedWidget;
  late Widget _leftButton;
  late Widget _rightButton;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initDialogWidgets();
  }

  void _initDialogWidgets() {
    final loc = ref.read(appLocalizationsProvider);
    _seedWidget = FormBuilder(
      key: _mySeedFormKey,
      child: FormBuilderTextField(
        name: 'password',
        style: context.bodyLarge,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: loc.password,
        ),
        validator: FormBuilderValidators.required(),
      ),
    );
    _leftButton = FilledButton(
      onPressed: () => context.pop(),
      child: Text(loc.cancel_button),
    );
    _rightButton = FilledButton(
      onPressed: _getSeed,
      child: Text(loc.confirm_button),
    );
  }

  void _getSeed() {
    if (_mySeedFormKey.currentState?.saveAndValidate() ?? false) {
      final password =
          _mySeedFormKey.currentState?.fields['password']?.value as String;

      final loc = ref.read(appLocalizationsProvider);
      setState(() {
        _seedWidget = const CircularProgressIndicator();
        _leftButton = const SizedBox.shrink();
        _rightButton =
            FilledButton(onPressed: null, child: Text(loc.ok_button));
      });

      final future = ref.read(walletStateProvider.notifier).getSeed(password);
      future.then(
        (value) {
          setState(() {
            _seedWidget = SeedContentWidget(value);
            _rightButton = FilledButton(
                onPressed: () => context.pop(), child: Text(loc.ok_button));
          });
        },
        onError: (_, __) => setState(() {
          _seedWidget = SelectableText(
            loc.oups,
          );
          _rightButton = FilledButton(
              onPressed: () => context.pop(), child: Text(loc.ok_button));
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc.my_seed,
        style: context.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Builder(
        builder: (BuildContext context) {
          final width = context.mediaSize.width * 0.8;

          return SizedBox(
            width: isDesktopDevice ? width : null,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: AppDurations.animFast),
              child: _seedWidget,
            ),
          );
        },
      ),
      actions: [
        _leftButton,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: AppDurations.animFast),
          child: _rightButton,
        ),
      ],
    );
  }
}
