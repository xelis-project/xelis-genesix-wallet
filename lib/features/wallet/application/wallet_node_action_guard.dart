import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class WalletNodeActionGuard {
  const WalletNodeActionGuard(this.ref);

  final Ref ref;

  bool get isNodeAvailable {
    final runtime = ref.read(walletRuntimeProvider);
    return runtime.isOnline &&
        runtime.connectionPhase == WalletConnectionPhase.connected;
  }

  bool ensureNodeAvailable({bool notify = true}) {
    if (isNodeAvailable) {
      return true;
    }

    if (notify) {
      showNodeRequiredWarning();
    }
    return false;
  }

  void showNodeRequiredWarning() {
    final loc = ref.read(appLocalizationsProvider);
    final settings = ref.read(settingsProvider);
    final runtime = ref.read(walletRuntimeProvider);
    final description =
        settings.walletOfflineMode ||
            runtime.connectionPhase == WalletConnectionPhase.offline
        ? loc.action_not_available_offline
        : runtime.connectionPhase == WalletConnectionPhase.connecting ||
              runtime.connectionPhase == WalletConnectionPhase.reconnecting
        ? loc.action_wait_for_node_connection
        : loc.action_requires_connected_node;

    ref
        .read(walletEffectBusProvider.notifier)
        .emit(
          WalletEffect.warning(
            title: loc.node_required,
            description: description,
          ),
        );
  }
}
