import 'package:flutter/material.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/balance_widget.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/topoheight_widget.dart';
import 'package:genesix/features/wallet/presentation/wallet_navigation_bar/components/wallet_address_widget.dart';
import 'package:genesix/shared/theme/constants.dart';

class WalletNavigationBar extends StatelessWidget {
  const WalletNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spaces.large),
      children: const [
        WalletAddressWidget(),
        SizedBox(height: Spaces.large),
        BalanceWidget(),
        SizedBox(height: Spaces.large),
        TopoHeightWidget(),
      ],
    );
  }
}
