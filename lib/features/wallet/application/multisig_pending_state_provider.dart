import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'multisig_pending_state_provider.g.dart';

@Riverpod(keepAlive: true)
class MultisigPendingState extends _$MultisigPendingState {
  @override
  bool build() {
    ref.watch(
      walletRuntimeProvider.select(
        (value) =>
            (value.name, value.address, value.network, value.multisigState),
      ),
    );
    return false;
  }

  void pendingState() {
    state = true;
  }
}
