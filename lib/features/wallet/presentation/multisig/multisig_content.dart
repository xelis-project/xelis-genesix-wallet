import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/presentation/address_book/address_widget.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/theme/build_context_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/faded_scroll.dart';
import 'package:genesix/shared/widgets/components/labeled_value.dart';
import 'package:go_router/go_router.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_participant.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class MultisigContent extends ConsumerStatefulWidget {
  const MultisigContent({super.key});

  @override
  ConsumerState createState() => _MultisigContentState();
}

class _MultisigContentState extends ConsumerState<MultisigContent> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final multisigState = ref.watch(
      walletStateProvider.select((value) => value.multisigState),
    );
    final pendingState = ref.watch(multisigPendingStateProvider);

    return AnimatedSwitcher(
      key: ValueKey<bool>(pendingState),
      duration: const Duration(milliseconds: AppDurations.animFast),
      child: pendingState
          ? _PendingChangesCard(message: loc.changes_in_progress)
          : multisigState.isSetup
          ? _ConfiguredMultisigView(
              loc: loc,
              state: multisigState,
              scrollController: _scrollController,
              ref: ref,
            )
          : _EmptyMultisigCallToAction(loc: loc),
    );
  }
}

class _PendingChangesCard extends StatelessWidget {
  const _PendingChangesCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spaces.medium),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: FCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Spaces.medium,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(
                      context.theme.colors.primary,
                    ),
                  ),
                ),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.theme.typography.base,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfiguredMultisigView extends StatelessWidget {
  const _ConfiguredMultisigView({
    required this.loc,
    required this.state,
    required this.scrollController,
    required this.ref,
  });

  final AppLocalizations loc;
  final MultisigState state;
  final ScrollController scrollController;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final participants = state.participants.toList(growable: false);
    final formattedTopoheight = NumberFormat.decimalPattern().format(
      state.topoheight,
    );

    Widget buildMetric(String title, String value) => LabeledValue.text(
      title,
      value,
      style: context.theme.typography.lg.copyWith(fontWeight: FontWeight.w600),
    );

    List<Widget> buildParticipantTiles() {
      if (participants.isEmpty) {
        return [
          Container(
            padding: const EdgeInsets.all(Spaces.medium),
            decoration: BoxDecoration(
              color: context.theme.colors.secondary,
              borderRadius: BorderRadius.circular(Spaces.medium),
              border: Border.all(color: context.theme.colors.border),
            ),
            child: Text(
              loc.no_multisig_configuration_found,
              style: context.theme.typography.base.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ),
        ];
      }

      return participants
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final MultisigParticipant participant = entry.value;

            final tile = Container(
              padding: const EdgeInsets.all(Spaces.medium),
              decoration: BoxDecoration(
                color: context.theme.colors.secondary,
                borderRadius: BorderRadius.circular(Spaces.medium),
                border: Border.all(color: context.theme.colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spaces.medium,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FBadge(
                        variant: .outline,
                        child: Text('#${index + 1}'),
                      ),
                      FTooltip(
                        tipBuilder: (context, controller) => Text(loc.copy),
                        child: FButton.icon(
                          variant: .ghost,
                          onPress: () => copyToClipboard(
                            participant.address,
                            ref,
                            loc.copied,
                          ),
                          child: const Icon(FIcons.copy, size: 18),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        copyToClipboard(participant.address, ref, loc.copied),
                    child: AddressWidget(participant.address),
                  ),
                ],
              ),
            );

            if (index == participants.length - 1) return tile;

            return Column(
              spacing: Spaces.medium,
              children: [
                tile,
                FDivider(),
              ],
            );
          })
          .toList(growable: false);
    }

    return Padding(
      padding: const EdgeInsets.all(Spaces.medium),
      child: FadedScroll(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spaces.extraLarge,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spaces.small,
                children: [
                  Text(
                    loc.multisig,
                    style: context.theme.typography.xl3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Review the current multisig configuration and participants.',
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              FCard(
                child: Column(
                  spacing: Spaces.large,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.information,
                      style: context.theme.typography.sm.copyWith(
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                    Wrap(
                      spacing: Spaces.large,
                      runSpacing: Spaces.large,
                      children: [
                        SizedBox(
                          width: 200,
                          child: buildMetric(
                            loc.threshold,
                            '${state.threshold}/${participants.length}',
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: buildMetric(
                            loc.participants,
                            participants.length.toString(),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: buildMetric(
                            loc.topoheight,
                            formattedTopoheight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FCard(
                child: Column(
                  spacing: Spaces.large,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Spaces.small,
                      children: [
                        Text(
                          loc.participants,
                          style: context.theme.typography.base.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Each entry below represents a wallet allowed to co-sign transactions.',
                          style: context.theme.typography.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    ...buildParticipantTiles(),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FButton(
                  variant: .destructive,
                  prefix: const Icon(FIcons.trash),
                  onPress: () {},
                  child: Text(loc.delete_wallet.capitalizeAll()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMultisigCallToAction extends StatelessWidget {
  const _EmptyMultisigCallToAction({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final mediaWidth = context.mediaWidth;
    final mediaHeight = context.mediaHeight;
    final breakpoints = context.theme.breakpoints;
    final bool isWide = mediaWidth >= breakpoints.md;
    final bool useHorizontalLayout = isWide && mediaHeight >= 620;
    final double maxWidth = useHorizontalLayout
        ? (mediaWidth * 0.55).clamp(520.0, 880.0).toDouble()
        : 420.0;
    final colors = context.theme.colors;

    Widget featurePill(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spaces.medium,
        vertical: Spaces.extraSmall,
      ),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(Spaces.large),
        border: Border.all(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32, maxWidth: 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: Spaces.extraSmall),
            Flexible(
              child: Text(
                label,
                style: context.theme.typography.xs.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );

    final double illustrationSize = useHorizontalLayout ? 140 : 104;

    final illustration = Container(
      width: illustrationSize,
      height: illustrationSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.18),
            colors.primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        FIcons.shieldCheck,
        size: useHorizontalLayout ? 68 : 52,
        color: colors.primary,
      ),
    );

    final textAlignment = useHorizontalLayout
        ? TextAlign.left
        : TextAlign.center;
    final crossAxis = useHorizontalLayout
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    final titleStyle = context.theme.typography.lg.copyWith(
      fontWeight: FontWeight.w600,
    );

    final bodyStyle = context.theme.typography.base.copyWith(
      color: colors.mutedForeground,
    );

    final secondaryBodyStyle = context.theme.typography.sm.copyWith(
      color: colors.mutedForeground,
    );

    final description = Column(
      crossAxisAlignment: crossAxis,
      spacing: Spaces.extraLarge,
      children: [
        Column(
          crossAxisAlignment: crossAxis,
          spacing: Spaces.smallMedium,
          children: [
            Text(
              'Collaborative security for your wallet',
              textAlign: textAlignment,
              style: titleStyle,
            ),
            Text(
              'Upgrade this wallet into a coordinated multisig vault managed with your trusted participants.',
              textAlign: textAlignment,
              style: bodyStyle,
            ),
            Text(
              'Outgoing transfers will only execute once the signing threshold you define is satisfied.',
              textAlign: textAlignment,
              style: secondaryBodyStyle,
            ),
          ],
        ),
        Wrap(
          spacing: Spaces.small,
          runSpacing: Spaces.small,
          alignment: useHorizontalLayout
              ? WrapAlignment.start
              : WrapAlignment.center,
          children: [
            featurePill(FIcons.users, 'Shared custodians'),
            featurePill(FIcons.lock, 'Approval workflow'),
            featurePill(FIcons.history, 'Audit trail'),
          ],
        ),
        Align(
          alignment: useHorizontalLayout
              ? Alignment.centerLeft
              : Alignment.center,
          child: FButton(
            onPress: () => context.go(AuthAppScreen.setupMultisig.toPath),
            child: Text(loc.setup),
          ),
        ),
      ],
    );

    final content = useHorizontalLayout
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              illustration,
              const SizedBox(width: Spaces.extraLarge),
              Expanded(child: description),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Spaces.large,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [illustration, description],
          );

    final outerPadding = EdgeInsets.symmetric(
      horizontal: useHorizontalLayout ? Spaces.extraLarge * 1.5 : Spaces.medium,
      vertical: useHorizontalLayout ? Spaces.extraLarge : Spaces.medium,
    );

    return SingleChildScrollView(
      padding: outerPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FCard(
            child: Padding(
              padding: EdgeInsets.all(
                useHorizontalLayout ? Spaces.extraLarge : Spaces.large,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
