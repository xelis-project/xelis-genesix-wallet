import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/shared/theme/constants.dart';

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
    final isOnline = ref.read(walletStateProvider).isOnline;
    if (isOnline) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
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
    final isOnline = ref.watch(
      walletStateProvider.select((value) => value.isOnline),
    );

    final color = isOnline
        ? context.theme.colors.primary
        : context.theme.colors.error;
    final text = isOnline ? loc.connected : loc.disconnected;

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
                      scale: isOnline ? _pulse.value : 1.0,
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
                // Slide from the bottom to the top if we connect
                // and from the top to the bottom if we disconnect
                final isNextConnected =
                    (child.key as ValueKey).value == loc.connected;
                final offsetBegin = isNextConnected
                    ? const Offset(0, 1)
                    : const Offset(0, -1);
                final offsetEnd = Offset.zero;
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: offsetBegin,
                    end: offsetEnd,
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
