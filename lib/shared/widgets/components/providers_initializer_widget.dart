import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/shared/providers/toast_provider.dart';

class ProvidersInitializerWidget extends ConsumerWidget {
  const ProvidersInitializerWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(activeWalletSessionProvider, (previous, next) {
      final sessionChanged = !identical(previous?.repository, next?.repository);
      if (sessionChanged) {
        ref.read(xswdRequestProvider.notifier).clearRequest();
      }

      final walletRuntime = ref.read(walletRuntimeProvider.notifier);
      if (next == null) {
        unawaited(walletRuntime.clearSession());
      } else {
        unawaited(walletRuntime.attachSession(next));
      }

      if (sessionChanged) {
        ref.invalidate(xswdApplicationsProvider);
      }

      unawaited(_syncXswdLifecycle(ref));
    });

    ref.listen(settingsProvider.select((settings) => settings.enableXswd), (
      previous,
      next,
    ) {
      if (previous == next) {
        return;
      }
      unawaited(_syncXswdLifecycle(ref));
    });

    ref.listen(walletRuntimeProvider.select((state) => state.isOnline), (
      previous,
      next,
    ) {
      if (previous == next) {
        return;
      }
      unawaited(_syncXswdLifecycle(ref));
    });

    ref.listen(walletEffectBusProvider, (previous, next) {
      if (next == null) {
        return;
      }
      if (previous?.id == next.id) {
        return;
      }

      final toastNotifier = ref.read(toastProvider.notifier);
      switch (next.effect) {
        case WalletInfoEffect(:final title):
          toastNotifier.showInformation(title: title);
        case WalletWarningEffect(:final title):
          toastNotifier.showWarning(title: title);
        case WalletErrorEffect(:final title, :final description):
          toastNotifier.showError(title: title, description: description);
        case WalletEventEffect(:final title, :final description):
          toastNotifier.showEvent(title: title, description: description);
        case WalletXswdEffect(
          :final title,
          :final description,
          :final showOpen,
        ):
          toastNotifier.showXswd(
            title: title,
            description: description,
            showOpen: showOpen,
          );
      }
    });

    return child;
  }
}

Future<void> _syncXswdLifecycle(WidgetRef ref) async {
  await ref
      .read(xswdControllerProvider)
      .sync(
        enabled: ref.read(settingsProvider).enableXswd,
        hasSession: ref.read(activeWalletSessionProvider) != null,
        isOnline: ref.read(walletRuntimeProvider).isOnline,
      );
}
