import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/shared/theme/constants.dart';
import 'package:genesix/shared/utils/utils.dart';

class ConnectionIndicator extends ConsumerStatefulWidget {
  const ConnectionIndicator({super.key});

  @override
  ConsumerState<ConnectionIndicator> createState() =>
      _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends ConsumerState<ConnectionIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _updateAnimation();
  }

  @override
  void didUpdateWidget(ConnectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    _syncAnimation(ref.read(walletRuntimeProvider).connectionPhase);
  }

  void _syncAnimation(WalletConnectionPhase phase) {
    final shouldAnimate = switch (phase) {
      WalletConnectionPhase.connected => true,
      WalletConnectionPhase.connecting => true,
      WalletConnectionPhase.reconnecting => true,
      WalletConnectionPhase.disconnected => false,
      WalletConnectionPhase.failed => false,
    };

    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
      return;
    }

    if (_controller.isAnimating) {
      _controller.stop();
    }
    if (_controller.value != 0.0) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final (phase, isOnline, isSyncing) = ref.watch(
      walletRuntimeProvider.select(
        (value) => (value.connectionPhase, value.isOnline, value.isSyncing),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncAnimation(phase);
    });

    final color = switch (phase) {
      WalletConnectionPhase.connected =>
        isSyncing ? Colors.orangeAccent : context.theme.colors.primary,
      WalletConnectionPhase.connecting => context.theme.colors.primary,
      WalletConnectionPhase.reconnecting => context.theme.colors.primary,
      WalletConnectionPhase.disconnected => context.theme.colors.error,
      WalletConnectionPhase.failed => context.theme.colors.error,
    };
    final text = switch (phase) {
      WalletConnectionPhase.connected => isSyncing ? 'Syncing' : loc.connected,
      WalletConnectionPhase.connecting =>
        '${loc.connect_node.capitalizeAll()}...',
      WalletConnectionPhase.reconnecting => '${loc.reconnect.capitalize()}...',
      WalletConnectionPhase.disconnected => loc.disconnected,
      WalletConnectionPhase.failed => loc.disconnected,
    };
    final shouldPulse = switch (phase) {
      WalletConnectionPhase.connected => true,
      WalletConnectionPhase.connecting => true,
      WalletConnectionPhase.reconnecting => true,
      WalletConnectionPhase.disconnected => false,
      WalletConnectionPhase.failed => false,
    };

    return Padding(
      padding: const EdgeInsets.all(Spaces.small),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Spaces.small,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing aura
                  Opacity(
                    opacity: 0.5,
                    child: Transform.scale(
                      scale: shouldPulse ? _pulse.value : 1.0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  // Point central
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: AppDurations.animNormal,
                    ),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              );
            },
          ),
          Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: AppDurations.animNormal),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Align(
                key: ValueKey<String>(text),
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  style: context.theme.typography.sm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
