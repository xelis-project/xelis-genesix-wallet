import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/providers/progress_report_provider.dart';

class WalletInitializerWidget extends ConsumerWidget {
  const WalletInitializerWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(walletStateProvider);
    ref.watch(progressReportStreamProvider);
    return child;
  }
}
