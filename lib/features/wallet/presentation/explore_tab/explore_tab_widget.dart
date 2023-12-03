import 'package:flutter/material.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/explore_tab/blockchain_data_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/explore_tab/node_data_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/explore_tab/wallet_data_widget.dart';

class Explore extends StatelessWidget {
  const Explore({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(child: BlockchainData()),
                Expanded(child: NodeData()),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: WalletData(),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
