import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/node_tab/components/node_info_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/node_tab/components/node_selector_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';

class NodeTab extends ConsumerWidget {
  const NodeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return ListView(
      padding: const EdgeInsets.all(Spaces.large),
      children: [
        Text(
          loc.remote_node,
          style: context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: Spaces.medium),
        const NodeSelectorWidget(),
        const SizedBox(height: Spaces.medium),
        const NodeInfoWidget(),
      ],
    );
  }
}
