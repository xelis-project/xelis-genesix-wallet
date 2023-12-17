import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/authentication/domain/login_action_enum.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/create_wallet_widget.dart';
import 'package:xelis_mobile_wallet/shared/storage/isar/isar_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/widgets/brightness_toggle.dart';
import 'package:xelis_mobile_wallet/features/authentication/presentation/open_wallet_widget.dart';

class AuthenticationScreen extends ConsumerWidget {
  const AuthenticationScreen({super.key, LoginAction? loginAction})
      : explicitAction = loginAction;

  final LoginAction? explicitAction;

  Widget _getScaffold(BuildContext context, Widget child) {
    return Scaffold(
      appBar: AppBar(
        actions: const [BrightnessToggle()],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: context.mediaSize.height),
                  child: child))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (explicitAction) {
      case LoginAction.create:
        return _getScaffold(context, const CreateWalletWidget());
      case LoginAction.open:
        return _getScaffold(context, const OpenWalletWidget());
      case null:
        return ref.watch(existingWalletNamesProvider).when(
              data: (data) => data.isNotEmpty
                  ? _getScaffold(context, const OpenWalletWidget())
                  : _getScaffold(context, const CreateWalletWidget()),
              // TODO: temp
              error: (err, stack) => Center(child: Text('Error: $err')),
              // TODO: temp
              loading: () => const Center(child: CircularProgressIndicator()),
            );
    }
  }
}
