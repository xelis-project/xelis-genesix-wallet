import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xelis_mobile_wallet/features/authentication/application/authentication_service.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/styles.dart';

class LogoutWidget extends ConsumerWidget {
  const LogoutWidget({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    context.loaderOverlay.show();
    await ref.read(authenticationProvider.notifier).logout();
    if (!context.mounted) return;
    context.loaderOverlay.hide();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spaces.medium),
      child: Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 2,
            child: OutlinedButton(
              child: Text(
                loc.logout,
              ),
              onPressed: () => _logout(context, ref),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
