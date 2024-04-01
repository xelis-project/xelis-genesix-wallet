import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/screens/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class ChangePasswordWidget extends ConsumerWidget {
  const ChangePasswordWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return ListTile(
      title: Text(
        loc.change_password,
        style: context.titleLarge,
      ),
      onTap: () {
        //context.push(AppScreen.changePassword.toPath);
      },
      trailing: const Icon(
        Icons.keyboard_arrow_right_rounded,
      ),
    );
  }
}
