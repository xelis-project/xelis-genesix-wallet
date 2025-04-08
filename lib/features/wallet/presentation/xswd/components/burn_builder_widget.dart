import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transaction_builder_mixin.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

class BurnBuilderWidget extends ConsumerWidget with TransactionBuilderMixin {
  final BurnBuilder burnBuilder;

  const BurnBuilderWidget({super.key, required this.burnBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              loc.burn,
              style: context.bodyLarge!.copyWith(
                color: context.moreColors.mutedColor,
              ),
            ),
          ],
        ),
        Builder(
          builder: (context) {
            final isXelisAsset =
                burnBuilder.asset == AppResources.xelisAsset.hash;
            final asset =
                isXelisAsset ? AppResources.xelisAsset.name : burnBuilder.asset;
            return buildLabeledText(context, loc.asset, asset);
          },
        ),
        Builder(
          builder: (context) {
            final isXelisAsset =
                burnBuilder.asset == AppResources.xelisAsset.hash;
            final amount =
                isXelisAsset
                    ? formatXelis(burnBuilder.amount)
                    : burnBuilder.amount.toString();
            return buildLabeledText(context, loc.amount.capitalize(), amount);
          },
        ),
      ],
    );
  }
}
