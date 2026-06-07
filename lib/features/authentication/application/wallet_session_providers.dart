import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_session_providers.g.dart';

@Riverpod(keepAlive: true)
class ActiveWalletSession extends _$ActiveWalletSession {
  @override
  WalletSession? build() {
    return null;
  }

  void setSession(WalletSession session) {
    state = session;
  }

  WalletSession? clearSession() {
    final previous = state;
    state = null;
    return previous;
  }
}

@riverpod
NativeWalletRepository? activeWalletRepository(Ref ref) {
  return ref.watch(activeWalletSessionProvider)?.repository;
}
