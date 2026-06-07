import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/authentication_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'authentication_provider.g.dart';

@riverpod
AuthenticationState authentication(Ref ref) {
  final session = ref.watch(activeWalletSessionProvider);
  if (session == null) {
    return const AuthenticationState.signedOut();
  }
  return AuthenticationState.signedIn(name: session.name);
}
