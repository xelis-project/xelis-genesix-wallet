import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _openFormKey = GlobalKey<FormBuilderState>(debugLabel: '_openFormKey');

  bool _hideOldPassword = true;

  bool _hideNewPassword1 = true;

  bool _hideNewPassword2 = true;

  late Widget _widgetConfirmation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initConfirmationButton();
  }

  void _initConfirmationButton() {
    final loc = ref.read(appLocalizationsProvider);
    _widgetConfirmation = SizedBox(
      width: 200,
      child: FilledButton(
        onPressed: _confirmNewPassword,
        child: Text(
          loc.confirm_button,
          style: context.titleMedium!.copyWith(color: context.colors.onPrimary),
        ),
      ),
    );
  }

  void _confirmNewPassword() {
    if (_openFormKey.currentState?.saveAndValidate() ?? false) {
      final loc = ref.read(appLocalizationsProvider);

      final oldPassword =
          _openFormKey.currentState?.value['old_password'] as String;
      final newPassword1 =
          _openFormKey.currentState?.value['new_password1'] as String;
      final newPassword2 =
          _openFormKey.currentState?.value['new_password2'] as String;

      if (oldPassword == newPassword1) {
        _openFormKey.currentState?.fields['new_password1']
            ?.invalidate(loc.same_old_new_password_error);
      } else if (newPassword1 != newPassword2) {
        _openFormKey.currentState?.fields['new_password2']
            ?.invalidate(loc.not_match_new_password_error);
      } else {
        setState(() {
          _widgetConfirmation = const CircularProgressIndicator();
        });
        ref
            .read(walletStateProvider.notifier)
            .changePassword(oldPassword, newPassword1)
            .then((value) {
          setState(() {
            _widgetConfirmation = Column(
              children: [
                Icon(
                  Icons.check_rounded,
                  color: context.colors.primary,
                ),
                const SizedBox(height: 8.0),
                Text(
                  loc.password_changed,
                  style: context.bodyMedium
                      ?.copyWith(color: context.colors.primary),
                ),
              ],
            );
          });
        }, onError: (_) {
          setState(() {
            _initConfirmationButton();
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.mediaSize.height),
            child: FormBuilder(
              key: _openFormKey,
              onChanged: () => _openFormKey.currentState!.save(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 24.0),
                                  child: IconButton(
                                    onPressed: () => context.pop(),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                loc.change_password,
                                style: context.headlineMedium!
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            FormBuilderTextField(
                              name: 'old_password',
                              style: context.bodyLarge,
                              autocorrect: false,
                              obscureText: _hideOldPassword,
                              decoration: InputDecoration(
                                hintText: loc.old_password,
                                suffixIcon: IconButton(
                                  icon: _hideOldPassword
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          color: context.colors.secondary,
                                        )
                                      : Icon(
                                          Icons.visibility_rounded,
                                          color: context.colors.primary,
                                        ),
                                  onPressed: () {
                                    setState(() {
                                      _hideOldPassword = !_hideOldPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: FormBuilderValidators.required(),
                            ),
                            const SizedBox(height: 16),
                            FormBuilderTextField(
                              name: 'new_password1',
                              style: context.bodyLarge,
                              autocorrect: false,
                              obscureText: _hideNewPassword1,
                              decoration: InputDecoration(
                                hintText: loc.new_password,
                                suffixIcon: IconButton(
                                  icon: _hideNewPassword1
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          color: context.colors.secondary,
                                        )
                                      : Icon(
                                          Icons.visibility_rounded,
                                          color: context.colors.primary,
                                        ),
                                  onPressed: () {
                                    setState(() {
                                      _hideNewPassword1 = !_hideNewPassword1;
                                    });
                                  },
                                ),
                              ),
                              validator: FormBuilderValidators.required(),
                            ),
                            const SizedBox(height: 16),
                            FormBuilderTextField(
                              name: 'new_password2',
                              style: context.bodyLarge,
                              autocorrect: false,
                              obscureText: _hideNewPassword2,
                              decoration: InputDecoration(
                                hintText: loc.confirm_password,
                                suffixIcon: IconButton(
                                  icon: _hideNewPassword2
                                      ? Icon(
                                          Icons.visibility_off_rounded,
                                          color: context.colors.secondary,
                                        )
                                      : Icon(
                                          Icons.visibility_rounded,
                                          color: context.colors.primary,
                                        ),
                                  onPressed: () {
                                    setState(() {
                                      _hideNewPassword2 = !_hideNewPassword2;
                                    });
                                  },
                                ),
                              ),
                              validator: FormBuilderValidators.required(),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: _widgetConfirmation,
                                ),
                              ),
                            ),
                            const Spacer(flex: 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
