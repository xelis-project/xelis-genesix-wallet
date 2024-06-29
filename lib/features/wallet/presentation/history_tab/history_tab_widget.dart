import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/burn_history_widget.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/coinbase_history_widget.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/incoming_history_widget.dart';
import 'package:genesix/features/wallet/presentation/history_tab/components/outgoing_history_widget.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/extensions.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.all(Spaces.large),
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              tabs: <Tab>[
                Tab(
                  text: loc.incoming,
                ),
                Tab(
                  text: loc.outgoing,
                ),
                Tab(
                  text: loc.coinbase,
                ),
                Tab(
                  text: loc.burn,
                ),
              ],
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: Spaces.medium),
                child: TabBarView(
                  children: <Widget>[
                    IncomingHistoryWidget(),
                    OutgoingHistoryWidget(),
                    CoinbaseHistoryWidget(),
                    BurnHistoryWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
