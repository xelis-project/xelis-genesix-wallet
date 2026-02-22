import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'multisig_pending_state_provider.g.dart';

@riverpod
class MultisigPendingState extends _$MultisigPendingState {
  @override
  bool build() {
    ref.watch(walletStateProvider.select((value) => value.multisigState));
    return false;
  }

  void pendingState() {
    state = true;
  }
}
