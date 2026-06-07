import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wallet_effect_bus_provider.g.dart';

@riverpod
class WalletEffectBus extends _$WalletEffectBus {
  int _nextEffectId = 0;

  @override
  WalletEffectEnvelope? build() {
    return null;
  }

  void emit(WalletEffect effect) {
    state = WalletEffectEnvelope(id: ++_nextEffectId, effect: effect);
  }
}
