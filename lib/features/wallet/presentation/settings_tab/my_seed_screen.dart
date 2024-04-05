import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_mobile_wallet/features/settings/presentation/components/layout_widget.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/wallet_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/extensions.dart';

import 'package:xelis_mobile_wallet/features/settings/application/app_localizations_provider.dart';
import 'package:xelis_mobile_wallet/shared/theme/constants.dart';
import 'package:xelis_mobile_wallet/shared/widgets/components/background_widget.dart';

class MySeedScreen extends ConsumerStatefulWidget {
  const MySeedScreen({super.key});

  @override
  ConsumerState<MySeedScreen> createState() => _MySeedScreenState();
}

class _MySeedScreenState extends ConsumerState<MySeedScreen> {
  String _seed = '';

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final wallet = ref.read(walletStateProvider);

    wallet.nativeWalletRepository!.getSeed().then((value) {
      if (mounted) {
        setState(() {
          _seed = value;
        });
      }
    });

/*
                  Icon(
                    Icons.warning_amber,
                    color: context.colors.primary,
                    size: 40,
                  ),*/

    return Background(
      child: ListView(
        padding: const EdgeInsets.all(Spaces.large),
        children: [
          BackHeader(title: loc.seed),
          const SizedBox(height: Spaces.medium),
          /*SelectableText.rich(
            TextSpan(
              style: context
                  .bodyMedium, //?.copyWith(color: context.colors.primary),
              children: [
                TextSpan(
                  text:
                      '${loc.seed_warning_message_1}\n${loc.seed_warning_message_2}\n\n',
                ),
              ],
            ),
          ),*/
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: context.colors.primary),
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: context.colors.primary,
                    size: 30,
                  ),
                  const SizedBox(width: Spaces.medium),
                  Expanded(
                    child: SelectableText.rich(
                      TextSpan(
                        style: context
                            .bodyMedium, //?.copyWith(color: context.colors.primary),
                        children: [
                          TextSpan(
                            text: '${loc.seed_warning}\n',
                            style: context.bodyMedium?.copyWith(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: loc.seed_warning_message_3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spaces.medium),
          Text(
            loc.seed_warning_message_4,
            style: context.titleMedium,
          ),
          const SizedBox(height: Spaces.small),
          Card.outlined(
            margin: const EdgeInsets.all(Spaces.none),
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: SelectableText(
                _seed,
                style: context.bodyLarge,
              ),
            ),
          )
        ],
      ),
    );
  }
}
