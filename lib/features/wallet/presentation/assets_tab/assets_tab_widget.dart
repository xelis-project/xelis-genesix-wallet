import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class AssetsTab extends ConsumerWidget {
  const AssetsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Center(
      child: Text(
        loc.coming_soon,
        style: context.displayMedium,
      ),
    );
  }
}
