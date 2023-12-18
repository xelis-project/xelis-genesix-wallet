import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

class WalletTab extends ConsumerStatefulWidget {
  const WalletTab({super.key});

  @override
  ConsumerState createState() => _WalletTabWidgetState();
}

class _WalletTabWidgetState extends ConsumerState<WalletTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'WALLET TAB',
        style: context.displayMedium,
      ),
    );
  }
}
