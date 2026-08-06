import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/router/route_utils.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/multisig_pending_state_provider.dart';
import 'package:genesix/features/wallet/application/transaction_review_provider.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/configured_multisig_view.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/multisig_introduction.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/shared/widgets/components/app_card.dart';
import 'package:go_router/go_router.dart';

class MultisigContent extends ConsumerStatefulWidget {
  const MultisigContent({super.key});

  @override
  ConsumerState<MultisigContent> createState() => _MultisigContentState();
}

class _MultisigContentState extends ConsumerState<MultisigContent> {
  final _scrollController = ScrollController();
  bool _isPreparingDeletion = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final multisigState = ref.watch(
      walletRuntimeProvider.select((value) => value.multisigState),
    );
    final pendingState = ref.watch(multisigPendingStateProvider);

    final Widget content;
    if (pendingState) {
      content = _PendingChangesCard(
        key: const ValueKey('multisig-pending'),
        message: loc.changes_in_progress,
      );
    } else if (multisigState != null) {
      content = ConfiguredMultisigView(
        key: const ValueKey('multisig-configured'),
        loc: loc,
        state: multisigState,
        scrollController: _scrollController,
        onCopyParticipant: _copyParticipant,
        isDeleting: _isPreparingDeletion,
        onDelete: _deleteMultisig,
      );
    } else {
      content = MultisigIntroduction(
        key: const ValueKey('multisig-introduction'),
        loc: loc,
        onConfigure: _openSetup,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: AppDurations.animFast),
      child: content,
    );
  }

  void _openSetup() => context.go(AuthAppScreen.setupMultisig.toPath);

  void _copyParticipant(String address) {
    final loc = ref.read(appLocalizationsProvider);
    copyToClipboard(address, ref, loc.copied);
  }

  Future<void> _deleteMultisig() async {
    if (_isPreparingDeletion) return;

    setState(() => _isPreparingDeletion = true);
    final commands = ref.read(walletCommandsProvider);
    final sessionIdentity = ref.read(activeWalletRepositoryProvider);
    if (sessionIdentity == null) {
      setState(() => _isPreparingDeletion = false);
      return;
    }
    try {
      final request = await commands.startDeleteMultisig();
      if (request == null) return;
      if (!mounted) {
        await commands.cancelPendingMultisigRequest(
          request: request,
          sessionIdentity: sessionIdentity,
        );
        return;
      }
      if (!identical(
        ref.read(activeWalletRepositoryProvider),
        sessionIdentity,
      )) {
        await commands.cancelPendingMultisigRequest(
          request: request,
          sessionIdentity: sessionIdentity,
        );
        return;
      }

      ref
          .read(transactionReviewProvider.notifier)
          .signaturePending(request, sessionIdentity: sessionIdentity);
      await context.push(AuthAppScreen.transactionReview.toPath);
    } finally {
      if (mounted) setState(() => _isPreparingDeletion = false);
    }
  }
}

class _PendingChangesCard extends StatelessWidget {
  const _PendingChangesCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spaces.medium),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: AppCard(
            clipBehavior: Clip.antiAlias,
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
                  style: context.theme.typography.body.md,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
