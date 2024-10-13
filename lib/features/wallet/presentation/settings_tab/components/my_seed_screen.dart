import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/widgets/components/custom_scaffold.dart';
import 'package:genesix/shared/widgets/components/generic_app_bar_widget.dart';

class MySeedScreen extends ConsumerStatefulWidget {
  const MySeedScreen({super.key});

  @override
  ConsumerState<MySeedScreen> createState() => _MySeedScreenState();
}

class _MySeedScreenState extends ConsumerState<MySeedScreen> {
  String _seed = '';

  @override
  void initState() {
    super.initState();
    final loc = ref.read(appLocalizationsProvider);
    final walletRepository = ref.read(
        walletStateProvider.select((state) => state.nativeWalletRepository));

    walletRepository!.getSeed().then((value) {
      setState(() {
        _seed = value;
      });
    },
        onError: (_, __) => setState(() {
              _seed = loc.oups;
            }));
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);

    return CustomScaffold(
      backgroundColor: Colors.transparent,
      appBar: GenericAppBar(title: loc.seed),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: Spaces.large),
        children: [
          const SizedBox(height: Spaces.medium),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.primary),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: context.colors.primary,
                              size: 30,
                            ),
                            const SizedBox(width: Spaces.medium),
                            Text(
                              loc.warning,
                              style: context.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spaces.extraSmall),
                        SelectableText(
                          loc.seed_warning_message_1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.seed_warning_message_2,
            style: context.titleMedium,
          ),
          const SizedBox(height: Spaces.medium),
          Card(
            borderOnForeground: false,
            margin: const EdgeInsets.all(Spaces.none),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spaces.medium),
                child: SelectableText(
                  _seed,
                  style: context.bodyLarge,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
