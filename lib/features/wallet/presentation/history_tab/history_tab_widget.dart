import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/burn_history_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/coinbase_history_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/incoming_history_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/outgoing_history_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              loc.history,
              style:
                  context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
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
            child: TabBarView(
              children: <Widget>[
                IncomingHistoryWidget(),
                OutgoingHistoryWidget(),
                CoinbaseHistoryWidget(),
                BurnHistoryWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
