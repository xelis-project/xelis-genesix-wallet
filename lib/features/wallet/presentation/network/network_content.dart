import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/node_info_provider.dart';
import 'package:genesix/features/wallet/presentation/network/daemon_info_widget.dart';
import 'package:genesix/features/wallet/presentation/network/node_card.dart';
import 'package:genesix/shared/theme/constants.dart';

class NetworkContent extends ConsumerWidget {
  const NetworkContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(nodeInfoProvider).valueOrNull;

    return Column(
      spacing: Spaces.extraLarge,
      children: [
        NodeCard(info),
        Expanded(child: DaemonInfoWidget(info)),
      ],
    );
  }
}
