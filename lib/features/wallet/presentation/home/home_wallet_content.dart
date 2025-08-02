import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/presentation/components/seed_content_dialog.dart';
import 'package:genesix/features/wallet/presentation/home/balance_card.dart';
import 'package:genesix/features/wallet/presentation/home/connection_status_card.dart';
import 'package:genesix/features/wallet/presentation/home/last_news_card.dart';
import 'package:genesix/features/wallet/presentation/home/last_transactions_card.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class HomeWalletContent extends ConsumerStatefulWidget {
  const HomeWalletContent({super.key});

  @override
  ConsumerState createState() => _HomeWalletContentState();
}

class _HomeWalletContentState extends ConsumerState<HomeWalletContent> {
  bool _dialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // if the dialog is already shown, do not show it again
    if (_dialogShown) return;
    _dialogShown = true;

    final extra = context.goRouterState.extra;
    if (extra is String) {
      final seed = extra;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showFDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context, style, animation) {
            return SeedContentDialog(style, animation, seed);
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spaces.small),
        child: Column(
          spacing: Spaces.medium,
          children: [
            ConnectionStatusCard(),
            BalanceCard(),
            LastTransactionsCard(),
            LastNewsCard(),
          ],
        ),
      ),
    );
  }
}
