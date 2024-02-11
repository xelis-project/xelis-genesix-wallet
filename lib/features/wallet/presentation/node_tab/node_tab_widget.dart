import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/node_tab/node_selector_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class NodeTab extends ConsumerWidget {
  const NodeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.remote_node,
                  style: context.headlineLarge!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const NodeSelectorWidget(),
                const Spacer(),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
