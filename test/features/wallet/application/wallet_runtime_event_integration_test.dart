import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_history_refresh_signal_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/network_nodes_state.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

void main() {
  group('WalletRuntime typed runtime events', () {
    test('rotates in cancel, offline, subscribe, online order and expected '
        'cancellation stays silent', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.attachAndWaitConnected();

      harness.repository.operations.clear();
      final failuresBefore = harness.failures.length;

      await harness.runtime.reconnect();
      await harness.waitUntil(
        () => harness.state.connectionPhase == WalletConnectionPhase.connected,
        reason: 'reconnection did not complete',
      );

      expect(harness.repository.operations, [
        'cancel:1',
        'offline',
        'subscribe:2',
        'online',
      ]);
      expect(harness.failures, hasLength(failuresBefore));

      harness.repository.operations.clear();
      await harness.runtime.disconnect();
      await harness.settle();

      expect(harness.repository.operations, ['cancel:2', 'offline']);
      expect(harness.state.connectionPhase, WalletConnectionPhase.disconnected);
      expect(harness.state.isOnline, isFalse);
      expect(harness.failures, hasLength(failuresBefore));
    });

    testWidgets(
      'automatic reconnect survives a retryable offline cleanup failure',
      (tester) async {
        final harness = _Harness();
        try {
          final attach = harness.runtime.attachSession(harness.session);
          await tester.pump();
          await attach;
          expect(
            harness.state.connectionPhase,
            WalletConnectionPhase.connected,
          );

          final failuresBefore = harness.failures.length;
          harness.repository
            ..operations.clear()
            ..setOfflineErrors.add(
              const wallet_flutter.XelisWalletOperationException(
                source: wallet_flutter.XelisWalletErrorSource.xelisWallet,
                operation:
                    wallet_flutter.XelisWalletOperation.walletNetworkDisconnect,
                code: wallet_flutter.XelisWalletErrorCode.networkFailure,
                supportId: 'XWF-1111-2222-3333-4444-5555',
                nativeKind: 'DAEMON_API_ERROR',
              ),
            );

          harness.repository.currentSubscription!.emit(
            const wallet_flutter.XelisWalletOffline(),
          );
          expect(
            harness.state.connectionPhase,
            WalletConnectionPhase.disconnected,
          );

          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
          expect(harness.state.connectionPhase, WalletConnectionPhase.failed);
          expect(harness.repository.operations, ['cancel:1', 'offline']);

          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
          await tester.pump();

          expect(
            harness.state.connectionPhase,
            WalletConnectionPhase.connected,
          );
          expect(harness.state.isOnline, isTrue);
          expect(harness.repository.operations, [
            'cancel:1',
            'offline',
            'offline',
            'subscribe:2',
            'online',
          ]);
          expect(harness.failures, hasLength(failuresBefore));
        } finally {
          final dispose = harness.dispose();
          await tester.pump();
          await dispose;
        }
      },
    );

    test(
      'an older pending clearSession cannot erase a newer session',
      () async {
        final harness = _Harness();
        final newerRepository = _FakeNativeWalletRepository(
          walletAddress: 'xel:newer-session',
        );
        addTearDown(() async {
          await harness.dispose();
          await newerRepository.closeControllers();
        });
        await harness.attachAndWaitConnected();
        final oldSubscription = harness.repository.currentSubscription!;
        final cancellationGate = Completer<void>();
        oldSubscription.cancelGate = cancellationGate;

        final oldClear = harness.runtime.clearSession();
        await oldSubscription.cancelStarted.future;
        final newerAttach = harness.runtime.attachSession(
          WalletSession(name: 'newer-wallet', repository: newerRepository),
        );

        cancellationGate.complete();
        await Future.wait([oldClear, newerAttach]);
        await harness.waitUntil(
          () =>
              harness.state.name == 'newer-wallet' &&
              harness.state.connectionPhase == WalletConnectionPhase.connected,
          reason: 'the newer session did not survive the older clearSession',
        );

        expect(harness.state.address, newerRepository.address);
        expect(harness.repository.businessEvents.hasListener, isFalse);
        expect(newerRepository.businessEvents.hasListener, isTrue);
        expect(
          [harness.repository, newerRepository]
              .expand((repository) => repository.subscriptions)
              .where((subscription) => !subscription.isCancelled),
          hasLength(1),
        );
      },
    );

    test(
      'concurrent attaches leave only the newest session listening',
      () async {
        final harness = _Harness();
        final supersededRepository = _FakeNativeWalletRepository(
          walletAddress: 'xel:superseded-session',
        );
        final winningRepository = _FakeNativeWalletRepository(
          walletAddress: 'xel:winning-session',
        );
        final cancellationGate = Completer<void>();
        addTearDown(() async {
          if (!cancellationGate.isCompleted) {
            cancellationGate.complete();
          }
          await harness.dispose().timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw StateError(
              'concurrent-attach cleanup remained pending; '
              'initial=${harness.repository.currentSubscription?.debugState} '
              'winning=${winningRepository.currentSubscription?.debugState}',
            ),
          );
          await supersededRepository.closeControllers();
          await winningRepository.closeControllers();
        });
        await harness.attachAndWaitConnected();
        final initialSubscription = harness.repository.currentSubscription!;
        initialSubscription.cancelGate = cancellationGate;

        final supersededAttach = harness.runtime.attachSession(
          WalletSession(
            name: 'superseded-wallet',
            repository: supersededRepository,
          ),
        );
        await initialSubscription.cancelStarted.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'initial cancellation did not start; '
            '${initialSubscription.debugState}',
          ),
        );
        final winningAttach = harness.runtime.attachSession(
          WalletSession(name: 'winning-wallet', repository: winningRepository),
        );

        cancellationGate.complete();
        await Future.wait([supersededAttach, winningAttach]).timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'concurrent attaches remained pending; '
            'initial=${initialSubscription.debugState} '
            'initialOps=${harness.repository.operations} '
            'supersededOps=${supersededRepository.operations} '
            'winningOps=${winningRepository.operations}',
          ),
        );
        await harness.waitUntil(
          () =>
              harness.state.name == 'winning-wallet' &&
              harness.state.connectionPhase == WalletConnectionPhase.connected,
          reason: 'the newest concurrent attach did not win',
        );

        expect(harness.state.address, winningRepository.address);
        expect(
          [
            harness.repository,
            supersededRepository,
            winningRepository,
          ].where((repository) => repository.businessEvents.hasListener),
          [winningRepository],
        );
        expect(supersededRepository.subscriptions, isEmpty);
        expect(
          [harness.repository, supersededRepository, winningRepository]
              .expand((repository) => repository.subscriptions)
              .where((subscription) => !subscription.isCancelled),
          hasLength(1),
        );

        final winningSubscription = winningRepository.currentSubscription!;
        await harness.runtime.clearSession().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'clearSession after concurrent attaches remained pending; '
            'winning=${winningSubscription.debugState}',
          ),
        );
        expect(winningSubscription.isCancelled, isTrue);
        expect(winningRepository.businessEvents.hasListener, isFalse);
      },
    );

    test(
      'a stale business subscription failure cannot erase a newer session',
      () async {
        final harness = _Harness();
        final staleRepository = _FakeNativeWalletRepository(
          walletAddress: 'xel:stale-session',
        );
        final winningRepository = _FakeNativeWalletRepository(
          walletAddress: 'xel:winning-session',
        );
        final staleSubscription =
            Completer<wallet_flutter.XelisWalletBusinessEventSubscription>();
        staleRepository.businessSubscriptionGate = staleSubscription;
        addTearDown(() async {
          await harness.dispose();
          await staleRepository.closeControllers();
          await winningRepository.closeControllers();
        });

        final staleAttach = harness.runtime.attachSession(
          WalletSession(name: 'stale-wallet', repository: staleRepository),
        );
        await staleRepository.businessSubscribeStarted.future;

        final winningAttach = harness.runtime.attachSession(
          WalletSession(name: 'winning-wallet', repository: winningRepository),
        );
        await winningAttach;
        final staleError = StateError('stale business subscribe failed');
        final staleExpectation = expectLater(
          staleAttach,
          throwsA(same(staleError)),
        );
        staleSubscription.completeError(staleError, StackTrace.current);
        await staleExpectation;

        await harness.waitUntil(
          () =>
              harness.state.name == 'winning-wallet' &&
              harness.state.connectionPhase == WalletConnectionPhase.connected,
          reason: 'the stale subscribe failure erased the winning session',
        );
        expect(harness.state.address, winningRepository.address);
        expect(winningRepository.businessEvents.hasListener, isTrue);
        expect(staleRepository.businessEvents.hasListener, isFalse);
      },
    );

    test(
      'prepareForClose blocks reconnect and cancels both streams silently',
      () async {
        final harness = _Harness();
        final cancellationGate = Completer<void>();
        addTearDown(() async {
          if (!cancellationGate.isCompleted) {
            cancellationGate.complete();
          }
          await harness.dispose();
        });
        await harness.attachAndWaitConnected();
        final subscription = harness.repository.currentSubscription!;
        subscription.cancelGate = cancellationGate;
        harness.repository.operations.clear();
        final failuresBefore = harness.failures.length;

        final prepareFuture = harness.runtime.prepareForClose();
        await subscription.cancelStarted.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'prepareForClose did not start runtime-stream cancellation',
          ),
        );
        await harness.runtime.reconnect();

        expect(
          harness.repository.operations.where(
            (operation) =>
                operation.startsWith('subscribe:') || operation == 'online',
          ),
          isEmpty,
        );

        cancellationGate.complete();
        await prepareFuture;
        await harness.settle();

        expect(harness.repository.operations, ['cancel:1', 'offline']);
        expect(subscription.isCancelled, isTrue);
        expect(subscription.isClosed, isTrue);
        expect(harness.repository.businessEvents.hasListener, isFalse);
        expect(
          harness.state.connectionPhase,
          WalletConnectionPhase.disconnected,
        );
        expect(harness.state.isOnline, isFalse);
        expect(harness.failures, hasLength(failuresBefore));
      },
    );

    test(
      'prepareForClose invalidates an attach already waiting on cancellation',
      () async {
        final harness = _Harness();
        final pendingRepository = _FakeNativeWalletRepository(
          walletAddress: 'xel:pending-session',
        );
        final cancellationGate = Completer<void>();
        addTearDown(() async {
          if (!cancellationGate.isCompleted) {
            cancellationGate.complete();
          }
          await harness.dispose();
          await pendingRepository.closeControllers();
        });
        await harness.attachAndWaitConnected();
        final subscription = harness.repository.currentSubscription!;
        subscription.cancelGate = cancellationGate;

        final pendingAttach = harness.runtime.attachSession(
          WalletSession(name: 'pending-wallet', repository: pendingRepository),
        );
        await subscription.cancelStarted.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'the pending attach did not start stream cancellation',
          ),
        );
        final prepareFuture = harness.runtime.prepareForClose();

        cancellationGate.complete();
        await Future.wait([pendingAttach, prepareFuture]).timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw StateError(
            'prepareForClose did not supersede the pending attach; '
            '${subscription.debugState}',
          ),
        );
        await harness.settle();

        expect(pendingRepository.businessEvents.hasListener, isFalse);
        expect(pendingRepository.subscriptions, isEmpty);
        expect(harness.repository.businessEvents.hasListener, isFalse);
        expect(
          harness.state.connectionPhase,
          WalletConnectionPhase.disconnected,
        );
        expect(harness.state.isOnline, isFalse);
      },
    );

    test('does not accept Online before setOnline succeeds', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      final onlineGate = Completer<void>();
      harness.repository
        ..emitOnlineBeforeSetOnlineCompletes = true
        ..setOnlineGate = onlineGate;

      await harness.runtime.attachSession(harness.session);
      await harness.waitUntil(
        () => harness.repository.operations.contains('online'),
        reason: 'setOnline was not reached',
      );
      await harness.settle();

      expect(harness.state.connectionPhase, WalletConnectionPhase.connecting);
      expect(harness.state.isOnline, isFalse);

      onlineGate.complete();
      await harness.waitUntil(
        () => harness.state.connectionPhase == WalletConnectionPhase.connected,
        reason: 'the post-setOnline fallback did not mark the wallet connected',
      );
      expect(harness.state.isOnline, isTrue);
    });

    test(
      'preserves topoheight values above the JavaScript safe range',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final topoheight = (BigInt.one << 60) + BigInt.from(12345);

        harness.repository.currentSubscription!.emit(
          wallet_flutter.XelisWalletTopoheightChanged(topoheight: topoheight),
        );

        await harness.waitUntil(
          () => harness.state.topoheight == topoheight,
          reason: 'the lossless topoheight was not applied',
        );
        expect(harness.state.topoheight, topoheight);
      },
    );

    test(
      'keeps SyncIssue non-terminal and preserves its XWF reference',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        const supportId = 'XWF-1111-2222-3333-4444-5555';
        const nativeFailure = wallet_flutter.XelisWalletOperationException(
          source: wallet_flutter.XelisWalletErrorSource.xelisWallet,
          operation: wallet_flutter.XelisWalletOperation.walletSync,
          code: wallet_flutter.XelisWalletErrorCode.operationFailed,
          supportId: supportId,
          diagnosticMessage: 'privileged native diagnostic',
          nativeKind: 'WALLET_SYNC_ERROR',
        );
        final failuresBefore = harness.failures.length;

        harness.repository.currentSubscription!.emit(
          const wallet_flutter.XelisWalletSyncIssue(failure: nativeFailure),
        );

        await harness.waitUntil(
          () => harness.failures.length == failuresBefore + 1,
          reason: 'SyncIssue did not emit a support-safe failure',
        );
        final failure = harness.failures.last;
        expect(failure.supportId, supportId);
        expect(failure.source, 'xelisWallet');
        expect(failure.operation, 'wallet.sync');
        expect(failure.code, 'operation.failed');
        expect(failure.nativeKind, 'WALLET_SYNC_ERROR');
        expect(
          failure.toString(),
          isNot(contains('privileged native diagnostic')),
        );
        expect(harness.state.connectionPhase, WalletConnectionPhase.connected);
        expect(harness.state.isOnline, isTrue);
        expect(harness.state.lastConnectionFailure, isNull);
      },
    );

    test(
      'reports an active Closed event once even when the stream ends',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        const supportId = 'XWF-AAAA-BBBB-CCCC-DDDD-EEEE';
        const nativeFailure = wallet_flutter.XelisWalletOperationException(
          source: wallet_flutter.XelisWalletErrorSource.xelisWalletFlutter,
          operation: wallet_flutter.XelisWalletOperation.walletEventsStream,
          code: wallet_flutter.XelisWalletErrorCode.streamClosedUnexpectedly,
          supportId: supportId,
        );
        final failuresBefore = harness.failures.length;
        final subscription = harness.repository.currentSubscription!;

        subscription.emit(
          const wallet_flutter.XelisWalletEventStreamClosed(
            reason: wallet_flutter
                .XelisWalletRuntimeStreamCloseReason
                .nativeChannelClosed,
            failure: nativeFailure,
          ),
        );

        await harness.waitUntil(
          () =>
              harness.state.connectionPhase == WalletConnectionPhase.failed &&
              subscription.isCancelled &&
              subscription.isClosed,
          reason: 'Closed did not terminate and immediately release its stream',
        );
        await subscription.closeStream();
        await harness.settle();

        expect(harness.failures, hasLength(failuresBefore + 1));
        expect(harness.failures.last.supportId, supportId);
        expect(harness.state.isOnline, isFalse);
        expect(
          harness.repository.operations.where(
            (operation) => operation == 'cancel:1',
          ),
          hasLength(1),
        );
      },
    );

    test(
      'coalesces a lag burst into one in-flight and one trailing reconcile',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final firstReconcileGate = Completer<void>();
        final reconciledTopoheight = (BigInt.one << 58) + BigInt.from(7);
        harness.repository
          ..resetReconciliationCounters()
          ..nextMultisigReadGate = firstReconcileGate
          ..daemonTopoheight = reconciledTopoheight;
        final historyBefore = harness.historyRefreshCount;
        const lagFailure = wallet_flutter.XelisWalletOperationException(
          source: wallet_flutter.XelisWalletErrorSource.xelisWalletFlutter,
          operation: wallet_flutter.XelisWalletOperation.walletEventsStream,
          code: wallet_flutter.XelisWalletErrorCode.streamLagged,
          supportId: 'XWF-1000-2000-3000-4000-5000',
        );
        final subscription = harness.repository.currentSubscription!;

        for (var index = 0; index < 3; index++) {
          subscription.emit(
            wallet_flutter.XelisWalletEventStreamDegraded(
              skippedEvents: BigInt.from(index + 1),
              failure: lagFailure,
            ),
          );
        }

        await harness.waitUntil(
          () => harness.repository.multisigReads == 1,
          reason: 'the first reconciliation did not start',
        );
        expect(harness.repository.maxConcurrentMultisigReads, 1);

        firstReconcileGate.complete();
        await harness.waitUntil(
          () =>
              harness.repository.multisigReads == 2 &&
              harness.historyRefreshCount == historyBefore + 2,
          reason: 'the coalesced trailing reconciliation did not complete',
        );
        await harness.settle();

        expect(harness.repository.multisigReads, 2);
        expect(harness.repository.daemonInfoReads, 2);
        expect(harness.repository.maxConcurrentMultisigReads, 1);
        expect(harness.state.topoheight, reconciledTopoheight);
        expect(harness.state.connectionPhase, WalletConnectionPhase.connected);
      },
    );

    test(
      'replaces one authoritative multisig configuration with another',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        harness.repository.multisigState = _multisigState(
          threshold: 1,
          topoheight: BigInt.one,
          participantCount: 1,
        );
        await harness.attachAndWaitConnected();
        expect(harness.state.multisigState?.threshold, 1);

        final replacement = _multisigState(
          threshold: 2,
          topoheight: (BigInt.one << 53) + BigInt.one,
          participantCount: 3,
        );
        harness.repository.multisigState = replacement;
        harness.repository.currentSubscription!.emit(
          wallet_flutter.XelisWalletEventStreamDegraded(
            skippedEvents: BigInt.one,
            failure: const wallet_flutter.XelisWalletOperationException(
              source: wallet_flutter.XelisWalletErrorSource.xelisWalletFlutter,
              operation: wallet_flutter.XelisWalletOperation.walletEventsStream,
              code: wallet_flutter.XelisWalletErrorCode.streamLagged,
              supportId: 'XWF-2222-3333-4444-5555-6666',
            ),
          ),
        );

        await harness.waitUntil(
          () => harness.state.multisigState?.threshold == 2,
          reason: 'the non-null multisig replacement was ignored',
        );

        expect(harness.state.multisigState?.participants, hasLength(3));
        expect(harness.state.multisigState?.topoheight, replacement.topoheight);
      },
    );

    test(
      'keeps business events active offline and handles all six typed variants',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final huge = (BigInt.one << 60) + BigInt.from(12345);
        final historyBefore = harness.historyRefreshCount;
        final effectsBefore = harness.effects.length;
        harness.repository.assetMetadata.addAll({
          'burn-asset': _assetData('Burn Asset', 'BRN'),
          'tracked-asset': _assetData('Tracked Asset', 'TRK'),
        });
        const newAssetMetadata = wallet_flutter.XelisWalletAssetMetadata(
          name: 'New Asset',
          ticker: 'NEW',
          decimals: 8,
          maxSupply: wallet_flutter.XelisWalletNoMaxSupply(),
          owner: wallet_flutter.XelisWalletNoAssetOwner(),
        );
        harness.repository.xelisBalance = huge;
        harness.repository.trackedBalances = {
          'balance-asset': BigInt.from(12345),
        };

        await harness.runtime.disconnect();
        expect(harness.repository.businessEvents.hasListener, isTrue);
        expect(
          harness.state.connectionPhase,
          WalletConnectionPhase.disconnected,
        );

        final burn = wallet_flutter.XelisWalletBurnEntry(
          asset: 'burn-asset',
          amount: huge,
          fee: huge,
          nonce: huge,
        );
        harness.repository.businessEvents
          ..emit(
            wallet_flutter.XelisWalletNewTransaction(
              transaction: wallet_flutter.XelisWalletTransactionEntry(
                hash: 'confirmed-hash',
                topoheight: huge,
                timestampMillis: huge,
                entry: burn,
              ),
            ),
          )
          ..emit(
            wallet_flutter.XelisWalletNewPendingTransaction(
              transaction: wallet_flutter.XelisWalletPendingTransaction(
                hash: 'pending-hash',
                timestampMillis: huge,
                entry: burn,
              ),
            ),
          )
          ..emit(
            wallet_flutter.XelisWalletBalanceChanged(
              asset: 'balance-asset',
              balance: huge,
            ),
          )
          ..emit(
            wallet_flutter.XelisWalletNewAsset(
              asset: wallet_flutter.XelisWalletAsset(
                assetHash: 'new-asset',
                topoheight: huge,
                metadata: newAssetMetadata,
              ),
            ),
          )
          ..emit(
            const wallet_flutter.XelisWalletAssetTracked(
              asset: 'tracked-asset',
            ),
          )
          ..emit(
            const wallet_flutter.XelisWalletAssetUntracked(
              asset: 'tracked-asset',
            ),
          );

        await harness.waitUntil(
          () =>
              harness.historyRefreshCount == historyBefore + 2 &&
              harness.effects.length >= effectsBefore + 5 &&
              harness.state.knownAssets.containsKey('new-asset') &&
              harness.state.knownAssets.containsKey('tracked-asset'),
          reason: 'the six typed business variants were not fully handled',
        );

        expect(harness.state.xelisBalance, huge);
        expect(harness.state.knownAssets['new-asset'], same(newAssetMetadata));
        expect(
          harness.repository.assetMetadataReads,
          isNot(contains('new-asset')),
        );
        expect(harness.state.trackedBalances, {
          'balance-asset': BigInt.from(12345),
        });
        expect(
          harness.state.connectionPhase,
          WalletConnectionPhase.disconnected,
        );
        expect(harness.failures, isEmpty);
      },
    );

    test(
      'coalesces business lag without failing the network connection',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        harness.repository.resetReconciliationCounters();
        final firstReconcileGate = Completer<void>();
        harness.repository.nextMultisigReadGate = firstReconcileGate;
        final historyBefore = harness.historyRefreshCount;
        final failuresBefore = harness.failures.length;
        const supportId = 'XWF-B111-B222-B333-B444-B555';
        final failure = wallet_flutter.XelisWalletOperationException(
          source: wallet_flutter.XelisWalletErrorSource.xelisWalletFlutter,
          operation:
              wallet_flutter.XelisWalletOperation.walletBusinessEventsStream,
          code: wallet_flutter.XelisWalletErrorCode.streamLagged,
          supportId: supportId,
          nativeKind: 'WALLET_BUSINESS_EVENTS_LAGGED',
        );

        for (var index = 0; index < 3; index++) {
          harness.repository.businessEvents.emit(
            wallet_flutter.XelisWalletBusinessEventStreamDegraded(
              skippedEvents: BigInt.from(index + 1),
              failure: failure,
            ),
          );
        }
        await harness.waitUntil(
          () => harness.repository.multisigReads == 1,
          reason: 'the first business reconciliation did not start',
        );
        firstReconcileGate.complete();
        await harness.waitUntil(
          () =>
              harness.repository.multisigReads == 2 &&
              harness.historyRefreshCount == historyBefore + 2,
          reason: 'the trailing business reconciliation did not complete',
        );

        expect(harness.repository.maxConcurrentMultisigReads, 1);
        expect(harness.repository.daemonInfoReads, 0);
        expect(harness.failures, hasLength(failuresBefore));
        expect(harness.state.connectionPhase, WalletConnectionPhase.connected);
      },
    );

    test('records a business reconciliation failure without surfacing a second '
        'UI failure', () async {
      talker.cleanHistory();
      addTearDown(talker.cleanHistory);
      final harness = _Harness();
      addTearDown(harness.dispose);
      await harness.attachAndWaitConnected();
      talker.cleanHistory();
      final effectsBefore = harness.effects.length;
      final failuresBefore = harness.failures.length;
      const hydrationSupportId = 'XWF-R111-R222-R333-R444-R555';
      const diagnostic = 'privileged reconciliation detail';
      const nativeFailure = wallet_flutter.XelisWalletOperationException(
        source: wallet_flutter.XelisWalletErrorSource.xelisCommon,
        operation: wallet_flutter.XelisWalletOperation.walletDaemonInfoRead,
        code: wallet_flutter.XelisWalletErrorCode.operationFailed,
        supportId: hydrationSupportId,
        nativeKind: 'BUSINESS_RECONCILIATION_NATIVE_FAILURE',
        diagnosticMessage: diagnostic,
      );
      const lagFailure = wallet_flutter.XelisWalletOperationException(
        source: wallet_flutter.XelisWalletErrorSource.xelisWalletFlutter,
        operation:
            wallet_flutter.XelisWalletOperation.walletBusinessEventsStream,
        code: wallet_flutter.XelisWalletErrorCode.streamLagged,
        supportId: 'XWF-R666-R777-R888-R999-R000',
        nativeKind: 'WALLET_BUSINESS_EVENTS_LAGGED',
      );
      harness.repository.xelisBalanceError = nativeFailure;

      harness.repository.businessEvents.emit(
        wallet_flutter.XelisWalletBusinessEventStreamDegraded(
          skippedEvents: BigInt.one,
          failure: lagFailure,
        ),
      );
      await harness.waitUntil(
        () => talker.history.any(
          (record) => record.message?.contains(hydrationSupportId) ?? false,
        ),
        reason: 'the reconciliation failure was not retained for support',
      );

      final supportRecord = talker.history.lastWhere(
        (record) => record.message?.contains(hydrationSupportId) ?? false,
      );
      expect(supportRecord.message, contains('source=xelisCommon'));
      expect(
        supportRecord.message,
        contains(wallet_flutter.XelisWalletOperation.walletDaemonInfoRead.id),
      );
      expect(supportRecord.message, contains(nativeFailure.code.id));
      expect(
        supportRecord.message,
        contains('BUSINESS_RECONCILIATION_NATIVE_FAILURE'),
      );
      expect(supportRecord.message, isNot(contains(diagnostic)));
      expect(harness.effects, hasLength(effectsBefore));
      expect(harness.failures, hasLength(failuresBefore));
      expect(harness.state.connectionPhase, WalletConnectionPhase.connected);
      expect(harness.state.lastConnectionFailure, isNull);
    });

    test(
      'prepareForClose waits for an in-flight business reconciliation',
      () async {
        final harness = _Harness();
        final reconciliationGate = Completer<void>();
        addTearDown(() async {
          if (!reconciliationGate.isCompleted) {
            reconciliationGate.complete();
          }
          await harness.dispose();
        });
        await harness.attachAndWaitConnected();
        harness.repository.resetReconciliationCounters();
        harness.repository.nextMultisigReadGate = reconciliationGate;
        const failure = wallet_flutter.XelisWalletOperationException(
          source: wallet_flutter.XelisWalletErrorSource.xelisWalletFlutter,
          operation:
              wallet_flutter.XelisWalletOperation.walletBusinessEventsStream,
          code: wallet_flutter.XelisWalletErrorCode.streamLagged,
          supportId: 'XWF-B666-B777-B888-B999-B000',
          nativeKind: 'WALLET_BUSINESS_EVENTS_LAGGED',
        );
        harness.repository.businessEvents.emit(
          wallet_flutter.XelisWalletBusinessEventStreamDegraded(
            skippedEvents: BigInt.one,
            failure: failure,
          ),
        );
        await harness.waitUntil(
          () => harness.repository.multisigReads == 1,
          reason: 'the business reconciliation did not start',
        );

        var prepared = false;
        final preparation = harness.runtime.prepareForClose().then(
          (_) => prepared = true,
        );
        await harness.settle();
        expect(prepared, isFalse);

        reconciliationGate.complete();
        await preparation;
        expect(prepared, isTrue);
        expect(harness.repository.businessEvents.hasListener, isFalse);
        expect(
          harness.state.connectionPhase,
          WalletConnectionPhase.disconnected,
        );
      },
    );

    test(
      'reports one typed business close with its native XWF reference',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final failuresBefore = harness.failures.length;
        const supportId = 'XWF-C111-C222-C333-C444-C555';
        final failure = wallet_flutter.XelisWalletOperationException(
          source: wallet_flutter.XelisWalletErrorSource.xelisWalletFlutter,
          operation:
              wallet_flutter.XelisWalletOperation.walletBusinessEventsStream,
          code: wallet_flutter.XelisWalletErrorCode.streamClosedUnexpectedly,
          supportId: supportId,
          nativeKind: 'WALLET_BUSINESS_EVENT_STREAM_CLOSED',
        );

        harness.repository.businessEvents.emit(
          wallet_flutter.XelisWalletBusinessEventStreamClosed(
            reason: wallet_flutter
                .XelisWalletBusinessStreamCloseReason
                .nativeChannelClosed,
            failure: failure,
          ),
        );

        await harness.waitUntil(
          () => harness.failures.length == failuresBefore + 1,
          reason: 'the typed business close was not surfaced',
        );
        await harness.settle();

        expect(harness.failures.last.supportId, supportId);
        expect(
          harness.failures.last.operation,
          wallet_flutter.XelisWalletOperation.walletBusinessEventsStream.id,
        );
        expect(harness.state.connectionPhase, WalletConnectionPhase.connected);
        expect(harness.state.lastConnectionFailure, isNull);
      },
    );

    test(
      'a business stream failure does not mark the connection failed',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final failuresBefore = harness.failures.length;

        harness.repository.businessEvents.addError(
          StateError('business stream failed'),
          StackTrace.current,
        );

        await harness.waitUntil(
          () => harness.failures.length == failuresBefore + 1,
          reason: 'the business stream failure was not surfaced',
        );
        expect(
          harness.failures.last.operation,
          'wallet.business_events.stream',
        );
        expect(harness.state.connectionPhase, WalletConnectionPhase.connected);
        expect(harness.state.isOnline, isTrue);
        expect(harness.state.lastConnectionFailure, isNull);
      },
    );

    test(
      'a business handler preserves a native XWF reference and keeps polling',
      () async {
        talker.cleanHistory();
        addTearDown(talker.cleanHistory);
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final failuresBefore = harness.failures.length;
        const supportId = 'XWF-H111-H222-H333-H444-H555';
        const diagnostic = 'privileged native handler detail';
        const nativeFailure = wallet_flutter.XelisWalletOperationException(
          source: wallet_flutter.XelisWalletErrorSource.xelisWallet,
          operation: wallet_flutter.XelisWalletOperation.walletDaemonInfoRead,
          code: wallet_flutter.XelisWalletErrorCode.operationFailed,
          supportId: supportId,
          nativeKind: 'BUSINESS_HANDLER_NATIVE_FAILURE',
          diagnosticMessage: diagnostic,
        );
        harness.repository.xelisBalanceError = nativeFailure;

        harness.repository.businessEvents.emit(
          wallet_flutter.XelisWalletBalanceChanged(
            asset: 'balance-asset',
            balance: BigInt.zero,
          ),
        );
        await harness.waitUntil(
          () => talker.history.any(
            (record) => record.message?.contains(supportId) ?? false,
          ),
          reason: 'the handler failure was not recorded with its XWF id',
        );

        final supportRecord = talker.history.lastWhere(
          (record) => record.message?.contains(supportId) ?? false,
        );
        expect(
          supportRecord.message,
          contains(wallet_flutter.XelisWalletOperation.walletDaemonInfoRead.id),
        );
        expect(supportRecord.message, contains(nativeFailure.code.id));
        expect(supportRecord.message, isNot(contains(diagnostic)));
        expect(harness.failures, hasLength(failuresBefore));

        harness.repository
          ..xelisBalanceError = null
          ..trackedBalances = {'after-handler-error': BigInt.one};
        harness.repository.businessEvents.emit(
          const wallet_flutter.XelisWalletAssetUntracked(
            asset: 'after-handler-error',
          ),
        );
        await harness.waitUntil(
          () =>
              harness.state.trackedBalances['after-handler-error'] ==
              BigInt.one,
          reason: 'business polling stopped after the handler failure',
        );
      },
    );

    test(
      'rescan is immediate, rolls back on failure, and ends on HistorySynced',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final failedRescan = Completer<void>();
        harness.repository.rescanGate = failedRescan;

        final failedFuture = harness.runtime.rescan();
        expect(harness.state.isRescanning, isTrue);
        failedRescan.completeError(StateError('rescan failed'));
        await failedFuture;
        expect(harness.state.isRescanning, isFalse);
        expect(harness.failures.last.operation, 'wallet.rescan');

        final successfulRescan = Completer<void>();
        harness.repository.rescanGate = successfulRescan;
        final historyBefore = harness.historyRefreshCount;
        final successfulFuture = harness.runtime.rescan();
        expect(harness.state.isRescanning, isTrue);
        successfulRescan.complete();
        await successfulFuture;
        expect(harness.state.isRescanning, isTrue);

        final historyTopoheight = (BigInt.one << 57) + BigInt.from(99);
        harness.repository.currentSubscription!.emit(
          wallet_flutter.XelisWalletHistorySynced(
            topoheight: historyTopoheight,
          ),
        );
        await harness.waitUntil(
          () =>
              !harness.state.isRescanning &&
              harness.historyRefreshCount == historyBefore + 1,
          reason: 'HistorySynced did not finish the rescan lifecycle',
        );

        expect(harness.state.topoheight, historyTopoheight);
        expect(harness.repository.rescanTopoheights, [
          BigInt.zero,
          BigInt.zero,
        ]);
      },
    );

    test(
      'Offline clears rescan state and suppresses its stale failure',
      () async {
        final harness = _Harness();
        addTearDown(harness.dispose);
        await harness.attachAndWaitConnected();
        final rescanGate = Completer<void>();
        harness.repository.rescanGate = rescanGate;
        final failuresBefore = harness.failures.length;

        final rescanFuture = harness.runtime.rescan();
        expect(harness.state.isRescanning, isTrue);
        harness.repository.currentSubscription!.emit(
          const wallet_flutter.XelisWalletOffline(),
        );
        await harness.waitUntil(
          () =>
              harness.state.connectionPhase ==
                  WalletConnectionPhase.disconnected &&
              !harness.state.isRescanning,
          reason: 'Offline did not clear the active rescan state',
        );

        rescanGate.completeError(StateError('stale rescan failure'));
        await rescanFuture;
        await harness.settle();

        expect(harness.failures, hasLength(failuresBefore));
      },
    );
  });
}

final class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWithValue(
          const SettingsState(locale: Locale('en')),
        ),
        networkNodesProvider.overrideWithValue(
          const NetworkNodesState(
            mainnetAddress: NodeAddress(
              name: 'local test node',
              url: 'ws://127.0.0.1:8080',
            ),
          ),
        ),
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      ],
    );
    runtime = container.read(walletRuntimeProvider.notifier);
    _effectSubscription = container.listen<WalletEffectEnvelope?>(
      walletEffectBusProvider,
      (_, next) {
        if (next != null) {
          effects.add(next.effect);
        }
      },
    );
    _historySubscription = container.listen<int>(
      walletHistoryRefreshSignalProvider,
      (_, next) => historyRefreshCount = next,
      fireImmediately: true,
    );
  }

  final repository = _FakeNativeWalletRepository();
  late final ProviderContainer container;
  late final WalletRuntime runtime;
  late final ProviderSubscription<WalletEffectEnvelope?> _effectSubscription;
  late final ProviderSubscription<int> _historySubscription;
  final List<WalletEffect> effects = [];
  int historyRefreshCount = 0;

  WalletSession get session =>
      WalletSession(name: 'test-wallet', repository: repository);

  WalletRuntimeState get state => container.read(walletRuntimeProvider);

  Iterable<AppFailure> get failures sync* {
    for (final effect in effects) {
      if (effect case WalletFailureEffect(:final failure)) {
        yield failure;
      }
    }
  }

  Future<void> attachAndWaitConnected() async {
    await runtime.attachSession(session);
    await waitUntil(
      () => state.connectionPhase == WalletConnectionPhase.connected,
      reason: 'initial wallet connection did not complete',
    );
  }

  Future<void> waitUntil(
    bool Function() predicate, {
    required String reason,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!predicate()) {
      if (DateTime.now().isAfter(deadline)) {
        fail(reason);
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> settle() async {
    for (var index = 0; index < 5; index++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> dispose() async {
    await runtime.clearSession();
    await repository.closeControllers();
    _effectSubscription.close();
    _historySubscription.close();
    container.dispose();
  }
}

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  _FakeNativeWalletRepository({this.walletAddress = 'xel:test-address'});

  final String walletAddress;
  final List<String> operations = [];
  final _FakeBusinessEventSubscription businessEvents =
      _FakeBusinessEventSubscription(generation: BigInt.one);
  final List<_FakeRuntimeEventSubscription> subscriptions = [];
  final List<BigInt> rescanTopoheights = [];
  final Completer<void> businessSubscribeStarted = Completer<void>();

  bool emitOnlineBeforeSetOnlineCompletes = false;
  bool nativeOnline = false;
  bool nativeSyncing = false;
  Completer<void>? setOnlineGate;
  final List<Object> setOfflineErrors = [];
  Completer<void>? rescanGate;
  Completer<void>? nextMultisigReadGate;
  Completer<wallet_flutter.XelisWalletBusinessEventSubscription>?
  businessSubscriptionGate;
  Object? xelisBalanceError;
  BigInt daemonTopoheight = BigInt.zero;
  BigInt xelisBalance = BigInt.zero;
  Map<String, BigInt> trackedBalances = {};
  final Map<String, wallet_flutter.XelisWalletAssetMetadata> assetMetadata = {};
  final List<String> assetMetadataReads = [];
  int multisigReads = 0;
  int concurrentMultisigReads = 0;
  int maxConcurrentMultisigReads = 0;
  int daemonInfoReads = 0;
  wallet_flutter.XelisWalletMultisigState? multisigState;

  _FakeRuntimeEventSubscription? get currentSubscription =>
      subscriptions.isEmpty ? null : subscriptions.last;

  @override
  String get address => walletAddress;

  @override
  wallet_flutter.XelisNetwork get network =>
      wallet_flutter.XelisNetwork.mainnet;

  @override
  Future<bool> get isOnline async => nativeOnline;

  @override
  Future<bool> get isSyncing async => nativeSyncing;

  @override
  Future<wallet_flutter.XelisWalletBusinessEventSubscription>
  subscribeBusinessEvents() async {
    if (!businessSubscribeStarted.isCompleted) {
      businessSubscribeStarted.complete();
    }
    final gate = businessSubscriptionGate;
    if (gate != null) {
      return gate.future;
    }
    return businessEvents;
  }

  @override
  Future<void> setOffline() async {
    operations.add('offline');
    nativeOnline = false;
    if (setOfflineErrors.isNotEmpty) {
      throw setOfflineErrors.removeAt(0);
    }
  }

  @override
  Future<wallet_flutter.XelisWalletRuntimeEventSubscription>
  subscribeRuntimeEvents() async {
    final subscription = _FakeRuntimeEventSubscription(
      generation: BigInt.from(subscriptions.length + 1),
      onCancel: (generation) => operations.add('cancel:$generation'),
    );
    subscriptions.add(subscription);
    operations.add('subscribe:${subscription.generation}');
    return subscription;
  }

  @override
  Future<void> setOnline({required String daemonAddress}) async {
    operations.add('online');
    if (emitOnlineBeforeSetOnlineCompletes) {
      currentSubscription!.emit(const wallet_flutter.XelisWalletOnline());
    }
    final gate = setOnlineGate;
    if (gate != null) {
      await gate.future;
      setOnlineGate = null;
    }
    nativeOnline = true;
  }

  @override
  Future<wallet_flutter.XelisWalletMultisigState?> getMultisigState() async {
    multisigReads++;
    concurrentMultisigReads++;
    if (concurrentMultisigReads > maxConcurrentMultisigReads) {
      maxConcurrentMultisigReads = concurrentMultisigReads;
    }
    final gate = nextMultisigReadGate;
    nextMultisigReadGate = null;
    try {
      if (gate != null) {
        await gate.future;
      }
      return multisigState;
    } finally {
      concurrentMultisigReads--;
    }
  }

  @override
  Future<BigInt> getXelisBalance() async {
    final error = xelisBalanceError;
    if (error != null) {
      throw error;
    }
    return xelisBalance;
  }

  @override
  Future<Map<String, BigInt>> getTrackedBalances() async => trackedBalances;

  @override
  Future<Map<String, wallet_flutter.XelisWalletAssetMetadata>>
  getKnownAssets() async => assetMetadata;

  @override
  Future<wallet_flutter.XelisWalletAssetMetadata> getAssetMetadata(
    String assetHash,
  ) async {
    assetMetadataReads.add(assetHash);
    return assetMetadata[assetHash] ?? _assetData(assetHash, 'TST');
  }

  @override
  Future<wallet_flutter.XelisDaemonInfo> getDaemonInfo() async {
    daemonInfoReads++;
    return _daemonInfo(topoheight: daemonTopoheight);
  }

  @override
  Future<void> rescan({required BigInt topoheight}) async {
    rescanTopoheights.add(topoheight);
    final gate = rescanGate;
    if (gate != null) {
      await gate.future;
      rescanGate = null;
    }
  }

  void resetReconciliationCounters() {
    multisigReads = 0;
    concurrentMultisigReads = 0;
    maxConcurrentMultisigReads = 0;
    daemonInfoReads = 0;
  }

  Future<void> closeControllers() async {
    await businessEvents.cancel();
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeBusinessEventSubscription
    implements wallet_flutter.XelisWalletBusinessEventSubscription {
  _FakeBusinessEventSubscription({required this.generation}) {
    _controller =
        StreamController<wallet_flutter.XelisWalletBusinessEventFrame>(
          sync: true,
          onCancel: cancel,
        );
  }

  @override
  final BigInt generation;
  late final StreamController<wallet_flutter.XelisWalletBusinessEventFrame>
  _controller;
  BigInt _sequence = BigInt.zero;
  Future<void>? _cancelFuture;
  bool _isCancelled = false;

  @override
  Stream<wallet_flutter.XelisWalletBusinessEventFrame> get events =>
      _controller.stream;

  @override
  bool get isCancelled => _isCancelled;

  bool get hasListener => _controller.hasListener;

  bool get isClosed => _controller.isClosed;

  void emit(wallet_flutter.XelisWalletBusinessEvent event) {
    _sequence += BigInt.one;
    _controller.add(
      wallet_flutter.XelisWalletBusinessEventFrame(
        contractVersion:
            wallet_flutter.XelisWalletBusinessEventContract.currentVersion,
        generation: generation,
        sequence: _sequence,
        event: event,
      ),
    );
  }

  void addError(Object error, StackTrace stackTrace) {
    _controller.addError(error, stackTrace);
  }

  Future<void> closeStream() => _controller.close();

  @override
  Future<void> cancel() {
    return _cancelFuture ??= _performCancel();
  }

  Future<void> _performCancel() async {
    _isCancelled = true;
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
  }
}

final class _FakeRuntimeEventSubscription
    implements wallet_flutter.XelisWalletRuntimeEventSubscription {
  _FakeRuntimeEventSubscription({
    required this.generation,
    required this.onCancel,
  }) {
    _controller = StreamController<wallet_flutter.XelisWalletRuntimeEventFrame>(
      sync: true,
      onListen: () => listenerStartedCount++,
      onCancel: () {
        listenerCancelCount++;
        return cancel();
      },
    );
  }

  @override
  final BigInt generation;
  final void Function(BigInt generation) onCancel;
  late final StreamController<wallet_flutter.XelisWalletRuntimeEventFrame>
  _controller;
  BigInt _sequence = BigInt.zero;
  bool _isCancelled = false;
  Future<void>? _cancelFuture;
  Future<void>? _closeFuture;
  Completer<void>? cancelGate;
  final Completer<void> cancelStarted = Completer<void>();
  int cancelInvocationCount = 0;
  int listenerStartedCount = 0;
  int listenerCancelCount = 0;
  bool cancelGateReleased = false;
  bool cancelCompleted = false;

  @override
  Stream<wallet_flutter.XelisWalletRuntimeEventFrame> get events =>
      _controller.stream;

  @override
  bool get isCancelled => _isCancelled;

  bool get isClosed => _controller.isClosed;

  void emit(wallet_flutter.XelisWalletRuntimeEvent event) {
    _sequence += BigInt.one;
    _controller.add(
      wallet_flutter.XelisWalletRuntimeEventFrame(
        contractVersion:
            wallet_flutter.XelisWalletRuntimeEventContract.currentVersion,
        generation: generation,
        sequence: _sequence,
        event: event,
      ),
    );
  }

  Future<void> closeStream() async {
    _closeFuture ??= _controller.close();
    await _closeFuture;
  }

  @override
  Future<void> cancel() {
    cancelInvocationCount++;
    return _cancelFuture ??= _performCancel();
  }

  Future<void> _performCancel() async {
    _isCancelled = true;
    if (!cancelStarted.isCompleted) {
      cancelStarted.complete();
    }
    onCancel(generation);
    final gate = cancelGate;
    if (gate != null) {
      await gate.future;
    }
    cancelGateReleased = true;
    _closeFuture ??= _controller.close();
    unawaited(_closeFuture);
    cancelCompleted = true;
  }

  String get debugState =>
      'generation=$generation isCancelled=$isCancelled isClosed=$isClosed '
      'cancelInvocations=$cancelInvocationCount '
      'listenerStarted=$listenerStartedCount '
      'listenerCancelled=$listenerCancelCount '
      'gateReleased=$cancelGateReleased cancelCompleted=$cancelCompleted';
}

wallet_flutter.XelisDaemonInfo _daemonInfo({required BigInt topoheight}) {
  return wallet_flutter.XelisDaemonInfo(
    height: topoheight,
    topoheight: topoheight,
    stableHeight: topoheight,
    stableTopoheight: topoheight,
    prunedTopoheight: null,
    topBlockHash: '00',
    circulatingSupply: BigInt.zero,
    burnedSupply: BigInt.zero,
    emittedSupply: BigInt.zero,
    maximumSupply: BigInt.zero,
    difficulty: '1',
    blockTimeTarget: BigInt.one,
    averageBlockTime: BigInt.one,
    blockReward: BigInt.zero,
    devReward: BigInt.zero,
    minerReward: BigInt.zero,
    mempoolSize: BigInt.zero,
    version: 'test',
    network: wallet_flutter.XelisNetwork.mainnet,
    blockVersion: 0,
  );
}

wallet_flutter.XelisWalletMultisigState _multisigState({
  required int threshold,
  required BigInt topoheight,
  required int participantCount,
}) {
  return wallet_flutter.XelisWalletMultisigState(
    threshold: threshold,
    participants: [
      for (var id = 0; id < participantCount; id++)
        wallet_flutter.XelisWalletMultisigParticipant(
          id: id,
          address: 'xel:participant-$id',
        ),
    ],
    topoheight: topoheight,
  );
}

wallet_flutter.XelisWalletAssetMetadata _assetData(
  String name,
  String ticker,
) => wallet_flutter.XelisWalletAssetMetadata(
  decimals: 8,
  name: name,
  ticker: ticker,
  maxSupply: const wallet_flutter.XelisWalletNoMaxSupply(),
  owner: const wallet_flutter.XelisWalletNoAssetOwner(),
);
