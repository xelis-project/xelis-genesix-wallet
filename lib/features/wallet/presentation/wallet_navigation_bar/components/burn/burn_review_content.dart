import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/shared/widgets/components/logo.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';

class BurnReviewContent extends ConsumerWidget {
  const BurnReviewContent(this.transaction, {super.key});

  final BurnTransaction transaction;

  bool get isXelisBurn => transaction.asset == AppResources.xelisHash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(appLocalizationsProvider);

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.only(top: Spaces.medium),
            child: Padding(
              padding: const EdgeInsets.all(Spaces.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Asset
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.asset,
                        style: context.theme.typography.base.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: Spaces.small),
                      isXelisBurn
                          ? Row(
                              children: [
                                Logo(
                                  imagePath:
                                      AppResources.greenBackgroundBlackIconPath,
                                ),
                                const SizedBox(width: Spaces.small),
                                Text(AppResources.xelisName),
                              ],
                            )
                          : Text(truncateText(transaction.asset)),
                    ],
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.amount.capitalize(),
                        style: context.theme.typography.base.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: Spaces.small),
                      SelectableText(
                        transaction.amount,
                        style: TextStyle(
                          color: context.theme.colors.foreground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spaces.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.fee,
                style: context.theme.typography.base.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              SelectableText(transaction.fee),
            ],
          ),
          const SizedBox(height: Spaces.small),
          FDivider(
            style: .delta(
              padding: .value(.symmetric(vertical: Spaces.small)),
              color: context.theme.colors.primary,
              width: 1,
            ),
          ),
          const SizedBox(height: Spaces.small),

          // Hash
          Text(
            loc.hash,
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
          ),
          const SizedBox(height: Spaces.extraSmall),
          SelectableText(
            transaction.txHash,
            style: TextStyle(color: context.theme.colors.primary),
          ),
          const SizedBox(height: Spaces.large),

          // Confirmation checkbox (still here, but now only controls state,
          // not the dialog itself)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: AppDurations.animFast),
            child: transaction.isBroadcasted
                ? const SizedBox.shrink()
                : FormBuilderCheckbox(
                    name: 'confirm_burn',
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.only(top: Spaces.small),
                      isDense: true,
                      fillColor: Colors.transparent,
                    ),
                    title: Text(
                      loc.burn_confirmation,
                      style: context.bodyMedium,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: loc.field_required_error,
                    ),
                    onChanged: (value) {
                      ref
                          .read(transactionReviewProvider.notifier)
                          .setConfirmation(value as bool);
                    },
                  ),
          ),

          const SizedBox(height: Spaces.extraSmall),
        ],
      ),
    );
  }
}
