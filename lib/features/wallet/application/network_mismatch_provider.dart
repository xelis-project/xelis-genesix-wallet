import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_mismatch_provider.g.dart';

@riverpod
bool networkMismatch(Ref ref) {
  return ref.watch(
    walletRuntimeProvider.select(
      (state) =>
          state.lastConnectionFailure?.category ==
          AppFailureCategory.networkMismatch,
    ),
  );
}
