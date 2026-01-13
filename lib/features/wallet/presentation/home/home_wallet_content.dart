import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/recovery_phrase/recovery_phrase_dialog.dart';
import 'package:genesix/features/wallet/presentation/home/balance_card.dart';
import 'package:genesix/features/wallet/presentation/home/connection_status_card.dart';
import 'package:genesix/features/wallet/presentation/home/last_news_card.dart';
import 'package:genesix/features/wallet/presentation/home/last_transactions_card.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';

class HomeWalletContent extends ConsumerStatefulWidget {
  const HomeWalletContent({super.key});

  @override
  ConsumerState createState() => _HomeWalletContentState();
}

class _HomeWalletContentState extends ConsumerState<HomeWalletContent> {
  bool _dialogShown = false;
  final _controller = ScrollController();

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
          useRootNavigator: true,
          context: context,
          barrierDismissible: false,
          builder: (context, style, animation) {
            return RecoveryPhraseDialog(style, animation, seed);
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadedScroll(
      controller: _controller,
      fadeFraction: 0.08,
      child: SingleChildScrollView(
        controller: _controller,
        child: Padding(
          padding: const EdgeInsets.only(
            top: Spaces.small,
            bottom: Spaces.medium,
          ),
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
      ),
    );
  }
}
