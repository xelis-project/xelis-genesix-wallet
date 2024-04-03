import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/burn_history_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/coinbase_history_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/incoming_history_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/presentation/history_tab/components/outgoing_history_widget.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';
import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Padding(
      padding: const EdgeInsets.all(Spaces.small),
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.history,
              style:
                  context.headlineLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Spaces.large),
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
      ),
    );
  }
}
