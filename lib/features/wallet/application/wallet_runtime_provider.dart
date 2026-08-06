import 'dart:async';
import 'dart:collection';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_event_message_builder.dart';
import 'package:genesix/features/wallet/application/wallet_transaction_asset_resolver.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'wallet_history_refresh_signal_provider.dart';

part 'wallet_runtime_provider.g.dart';

/// Conservative retry policy for wallet connection failures.
///
/// A disconnect without a preceding failure remains retryable. Once a failure
/// exists, only the package-owned network category permits automatic retry.
bool isRetryableWalletConnectionFailure(AppFailure? failure) {
  return failure == null ||
      failure.category == AppFailureCategory.networkFailure ||
      failure.category == AppFailureCategory.operationInProgress;
}

@Riverpod(keepAlive: true)
class WalletRuntime extends _$WalletRuntime {
  static const _autoReconnectDelay = Duration(seconds: 5);

  NativeWalletRepository? _repository;
  _BusinessEventContext? _businessEventContext;
  _RuntimeEventContext? _runtimeEventContext;
  Timer? _autoReconnectTimer;
  bool _connectionIntentsBlocked = false;
  final _transitionQueue = _SerialAsyncQueue();
  int _connectionRequestId = 0;
  int _sessionLifecycleId = 0;
  int _connectionSucceededRequestId = -1;
  int _lastReportedConnectionFailureId = -1;

  @override
  WalletRuntimeState build() {
    ref.onDispose(_disposeRuntimeResources);
    return _emptyRuntimeState();
  }

  Future<void> attachSession(WalletSession session) async {
    if (identical(_repository, session.repository) &&
        state.name == session.name &&
        !_connectionIntentsBlocked) {
      return;
    }

    _connectionIntentsBlocked = true;
    final lifecycleId = ++_sessionLifecycleId;
    _connectionRequestId++;
    _invalidateRuntimeEventContext();
    _invalidateBusinessEventContext();
    _connectionSucceededRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    await _cancelEventSubscriptions();
    if (!_isCurrentSessionLifecycle(lifecycleId)) {
      return;
    }

    _repository = session.repository;
    state = _runtimeStateFromSession(
      session,
      _selectedNodeForNetwork(session.network),
    );
    try {
      final subscribed = await _subscribeBusinessEvents(
        session.repository,
        lifecycleId,
      );
      if (!subscribed) {
        return;
      }
    } catch (_) {
      if (_isCurrentSessionLifecycle(lifecycleId) &&
          _isActiveRepository(session.repository)) {
        _repository = null;
        state = _emptyRuntimeState();
        _connectionIntentsBlocked = false;
      }
      rethrow;
    }
    _connectionIntentsBlocked = false;

    if (ref.read(settingsProvider).walletOfflineMode) {
      unawaited(_enterOfflineMode(repository: session.repository));
      return;
    }

    unawaited(connect());
  }

  Future<bool> _subscribeBusinessEvents(
    NativeWalletRepository repository,
    int lifecycleId,
  ) async {
    final subscription = await repository.subscribeBusinessEvents();
    if (!_isCurrentSessionLifecycle(lifecycleId) ||
        !_isActiveRepository(repository)) {
      await subscription.cancel();
      return false;
    }

    final context = _BusinessEventContext(
      repository: repository,
      subscription: subscription,
    );
    _businessEventContext = context;
    final pump = _consumeBusinessEvents(context);
    context.pump = pump;
    unawaited(pump);
    return true;
  }

  Future<void> _consumeBusinessEvents(_BusinessEventContext context) async {
    try {
      while (await context.iterator.moveNext()) {
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        final frame = context.iterator.current;
        if (frame.generation != context.generation) {
          throw StateError('Unexpected wallet business event generation.');
        }
        try {
          await _onBusinessEvent(context, frame);
        } catch (error, stackTrace) {
          if (!_isCurrentBusinessEventContext(context)) {
            return;
          }
          recordAppFailure(
            error,
            stackTrace,
            operation: 'wallet.business_events.handle',
            applicationCode: 'wallet_business_event_handler_failed',
            contextBuilder: () =>
                'eventType=${frame.event.runtimeType} '
                'errorType=${error.runtimeType} '
                'generation=${frame.generation} sequence=${frame.sequence}',
          );
        }
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
      }
      _handleBusinessEventStreamDone(context);
    } catch (error, stackTrace) {
      _handleBusinessEventStreamError(context, error, stackTrace);
    } finally {
      if (context.terminationClaimed &&
          identical(_businessEventContext, context)) {
        try {
          await _cancelBusinessEventSubscription();
        } catch (error, stackTrace) {
          logDiagnosticError(
            'wallet.business_events.terminal_cleanup',
            error,
            stackTrace: stackTrace,
            contextBuilder: () => 'generation=${context.generation}',
          );
        }
      }
    }
  }

  Future<void> clearSession() async {
    _connectionIntentsBlocked = true;
    final lifecycleId = ++_sessionLifecycleId;
    _connectionRequestId++;
    _invalidateRuntimeEventContext();
    _invalidateBusinessEventContext();
    _connectionSucceededRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    Object? cancellationError;
    StackTrace? cancellationStackTrace;
    try {
      await _cancelEventSubscriptions();
    } catch (error, stackTrace) {
      cancellationError = error;
      cancellationStackTrace = stackTrace;
    } finally {
      if (_isCurrentSessionLifecycle(lifecycleId)) {
        _repository = null;
        state = _emptyRuntimeState();
      }
    }
    if (cancellationError != null) {
      Error.throwWithStackTrace(cancellationError, cancellationStackTrace!);
    }
  }

  Future<void> connect() async {
    if (_connectionIntentsBlocked) {
      return;
    }
    final selectedNode = _selectedNodeForCurrentNetwork();
    if (ref.read(settingsProvider).walletOfflineMode) {
      await _enterOfflineMode(selectedNode: selectedNode);
      return;
    }

    await _queueConnectionTransition(
      selectedNode: selectedNode,
      phase: WalletConnectionPhase.connecting,
      persistSelection: false,
      reportFailure: true,
    );
  }

  Future<void> setOfflineMode(bool enabled) async {
    if (_connectionIntentsBlocked) {
      return;
    }
    if (!enabled) {
      await reconnect();
      return;
    }

    await _enterOfflineMode(
      selectedNode: state.selectedNode ?? _selectedNodeForCurrentNetwork(),
    );
  }

  Future<void> disconnect() async {
    if (_connectionIntentsBlocked) {
      return;
    }
    final requestId = ++_connectionRequestId;
    _invalidateRuntimeEventContext();
    _connectionSucceededRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    _markDisconnectedState(
      selectedNode: state.selectedNode ?? _selectedNodeForCurrentNetwork(),
      clearError: true,
    );

    await _enqueueTransition(() async {
      final repository = _repository;
      if (repository == null ||
          !_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }
      Object? cancellationError;
      StackTrace? cancellationStackTrace;
      try {
        await _cancelRuntimeEventSubscription();
      } catch (error, stackTrace) {
        cancellationError = error;
        cancellationStackTrace = stackTrace;
      }
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }
      try {
        await repository.setOffline();
      } catch (error, stackTrace) {
        if (!_isCurrentConnectionRequest(requestId, repository)) {
          return;
        }
        final failure = recordAppFailure(
          error,
          stackTrace,
          operation: 'wallet.network.disconnect',
          applicationCode: 'wallet_network_disconnect_failed',
        );
        _markConnectionFailedState(failure);
        _emitFailure(failure: failure);
        return;
      }
      if (cancellationError != null &&
          _isCurrentConnectionRequest(requestId, repository)) {
        final failure = recordAppFailure(
          cancellationError,
          cancellationStackTrace!,
          operation: 'wallet.events.cancel',
          applicationCode: 'wallet_event_stream_cancel_failed',
        );
        _markConnectionFailedState(failure);
        _emitFailure(failure: failure);
      }
    });
  }

  Future<void> prepareForClose() async {
    _connectionIntentsBlocked = true;
    _sessionLifecycleId++;
    final requestId = ++_connectionRequestId;
    _invalidateRuntimeEventContext();
    _invalidateBusinessEventContext();
    _connectionSucceededRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    _markDisconnectedState(clearError: true);

    await _enqueueTransition(() async {
      final repository = _repository;
      if (repository == null ||
          !_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }
      Object? cancellationError;
      StackTrace? cancellationStackTrace;
      try {
        await _cancelEventSubscriptions();
      } catch (error, stackTrace) {
        cancellationError = error;
        cancellationStackTrace = stackTrace;
      }
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }
      await repository.setOffline();
      if (cancellationError != null) {
        Error.throwWithStackTrace(cancellationError, cancellationStackTrace!);
      }
    });
  }

  void _markDisconnectedState({
    NodeAddress? selectedNode,
    bool clearError = false,
  }) {
    state = state.copyWith(
      isOnline: false,
      isSyncing: false,
      isRescanning: false,
      connectionPhase: WalletConnectionPhase.disconnected,
      selectedNode: selectedNode ?? state.selectedNode,
      lastConnectionFailure: clearError ? null : state.lastConnectionFailure,
    );
  }

  void _markConnectionTransitionState({
    required NodeAddress selectedNode,
    required WalletConnectionPhase phase,
  }) {
    state = state.copyWith(
      isOnline: false,
      isSyncing: false,
      isRescanning: false,
      connectionPhase: phase,
      selectedNode: selectedNode,
      lastConnectionFailure: null,
    );
  }

  void _markConnectedState() {
    state = state.copyWith(
      isOnline: true,
      connectionPhase: WalletConnectionPhase.connected,
      lastConnectionFailure: null,
    );
    _lastReportedConnectionFailureId = -1;
  }

  void _markOfflineEventState() {
    state = state.copyWith(
      isOnline: false,
      isSyncing: false,
      isRescanning: false,
      connectionPhase: switch (state.connectionPhase) {
        WalletConnectionPhase.failed => WalletConnectionPhase.failed,
        WalletConnectionPhase.offline => WalletConnectionPhase.offline,
        _ => WalletConnectionPhase.disconnected,
      },
    );
  }

  void _markOfflineModeState({NodeAddress? selectedNode}) {
    state = state.copyWith(
      isOnline: false,
      isSyncing: false,
      isRescanning: false,
      connectionPhase: WalletConnectionPhase.offline,
      selectedNode: selectedNode ?? state.selectedNode,
      lastConnectionFailure: null,
    );
  }

  void _markOfflineDuringConnectionTransition() {
    state = state.copyWith(isOnline: false, isSyncing: false);
  }

  void _markConnectionFailedState(AppFailure failure) {
    _invalidateRuntimeEventContext();
    _connectionSucceededRequestId = -1;
    _cancelAutoReconnect();
    state = state.copyWith(
      isOnline: false,
      isSyncing: false,
      isRescanning: false,
      connectionPhase: WalletConnectionPhase.failed,
      lastConnectionFailure: failure,
    );
  }

  Future<void> reconnect([NodeAddress? nodeAddress]) async {
    if (_connectionIntentsBlocked) {
      return;
    }
    final selectedNode = nodeAddress ?? _selectedNodeForCurrentNetwork();
    if (ref.read(settingsProvider).walletOfflineMode) {
      await _enterOfflineMode(
        selectedNode: selectedNode,
        persistSelection: nodeAddress != null,
      );
      return;
    }

    final phase = switch (state.connectionPhase) {
      WalletConnectionPhase.connected => WalletConnectionPhase.reconnecting,
      WalletConnectionPhase.connecting => WalletConnectionPhase.reconnecting,
      WalletConnectionPhase.reconnecting => WalletConnectionPhase.reconnecting,
      WalletConnectionPhase.offline => WalletConnectionPhase.reconnecting,
      WalletConnectionPhase.failed => WalletConnectionPhase.reconnecting,
      WalletConnectionPhase.disconnected =>
        state.selectedNode == null
            ? WalletConnectionPhase.connecting
            : WalletConnectionPhase.reconnecting,
    };

    await _queueConnectionTransition(
      selectedNode: selectedNode,
      phase: phase,
      persistSelection: nodeAddress != null,
      reportFailure: true,
    );
  }

  Future<void> rescan() async {
    if (!_ensureConnectedNodeAvailable()) {
      return;
    }

    final repository = _repository;
    final runtimeContext = _runtimeEventContext;
    if (repository == null ||
        runtimeContext == null ||
        !_isCurrentRuntimeEventContext(runtimeContext)) {
      return;
    }
    final requestId = _connectionRequestId;
    state = state.copyWith(isRescanning: true);

    try {
      await repository.rescan(topoheight: BigInt.zero);
    } catch (error, stackTrace) {
      if (!_canApplyRepositoryResult(
            repository,
            requestId: requestId,
            runtimeContext: runtimeContext,
          ) ||
          state.connectionPhase != WalletConnectionPhase.connected) {
        return;
      }
      state = state.copyWith(isRescanning: false);
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.rescan',
        applicationCode: 'wallet_rescan_failed',
      );
      _emitFailure(title: 'Rescan failed', failure: failure);
    }
  }

  Future<void> _updateMultisigState(_BusinessEventContext context) async {
    final repository = context.repository;
    final multisig = await repository.getMultisigState();
    if (_isCurrentBusinessEventContext(context)) {
      state = state.copyWith(multisigState: multisig);
    }
  }

  Future<void> _hydrateRuntimeState(
    NativeWalletRepository repository, {
    int? requestId,
    _RuntimeEventContext? runtimeContext,
    _BusinessEventContext? businessContext,
    bool emitFailure = true,
  }) async {
    try {
      final multisig = await repository.getMultisigState();
      if (!_canApplyRepositoryResult(
        repository,
        requestId: requestId,
        runtimeContext: runtimeContext,
        businessContext: businessContext,
      )) {
        return;
      }

      final xelisBalance = await repository.getXelisBalance();
      if (!_canApplyRepositoryResult(
        repository,
        requestId: requestId,
        runtimeContext: runtimeContext,
        businessContext: businessContext,
      )) {
        return;
      }

      final balances = await repository.getTrackedBalances();
      if (!_canApplyRepositoryResult(
        repository,
        requestId: requestId,
        runtimeContext: runtimeContext,
        businessContext: businessContext,
      )) {
        return;
      }

      final knownAssets = await repository.getKnownAssets();
      if (!_canApplyRepositoryResult(
        repository,
        requestId: requestId,
        runtimeContext: runtimeContext,
        businessContext: businessContext,
      )) {
        return;
      }

      state = state.copyWith(
        multisigState: multisig,
        xelisBalance: xelisBalance,
        trackedBalances: sortMapByKey(balances),
        knownAssets: sortMapByKey(knownAssets),
      );
    } catch (error, stackTrace) {
      if (!_canApplyRepositoryResult(
        repository,
        requestId: requestId,
        runtimeContext: runtimeContext,
        businessContext: businessContext,
      )) {
        return;
      }
      final failure = recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.state.hydrate',
        applicationCode: 'wallet_state_hydration_failed',
      );
      if (emitFailure) {
        _emitFailure(failure: failure);
      }
    }
  }

  Future<void> _refreshSyncingState(
    NativeWalletRepository repository, {
    int? requestId,
    _RuntimeEventContext? runtimeContext,
  }) async {
    try {
      final isSyncing = await repository.isSyncing;
      if (!_canApplyRepositoryResult(
        repository,
        requestId: requestId,
        runtimeContext: runtimeContext,
      )) {
        return;
      }

      state = state.copyWith(
        isSyncing: switch (state.connectionPhase) {
          WalletConnectionPhase.failed => false,
          WalletConnectionPhase.offline => false,
          WalletConnectionPhase.disconnected => false,
          _ => isSyncing,
        },
      );
    } catch (error, stackTrace) {
      if (_canApplyRepositoryResult(
        repository,
        requestId: requestId,
        runtimeContext: runtimeContext,
      )) {
        logDiagnosticError(
          'wallet.sync.status.read',
          error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _onBusinessEvent(
    _BusinessEventContext context,
    wallet_flutter.XelisWalletBusinessEventFrame frame,
  ) async {
    if (!_isCurrentBusinessEventContext(context)) {
      return;
    }

    final repository = context.repository;
    final loc = ref.read(appLocalizationsProvider);
    final event = frame.event;

    switch (event) {
      case wallet_flutter.XelisWalletNewTransaction():
        logDiagnostic(
          () =>
              'Wallet event: type=NewTransaction '
              'hash=${event.transaction.hash} '
              'topoheight=${event.transaction.topoheight}',
        );
        await _updateMultisigState(context);
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }

        final txType = event.transaction.entry;

        await _ensureKnownAssetsForTransaction(context, txType);
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        ref.read(walletHistoryRefreshSignalProvider.notifier).bump();
        final messageBuilder = _eventMessageBuilder(loc);

        switch (txType) {
          case wallet_flutter.XelisWalletIncomingEntry():
            final message = await messageBuilder.incomingTransaction(txType);
            if (!_isCurrentBusinessEventContext(context)) {
              return;
            }
            _emitEvent(
              title: loc.new_incoming_transaction.capitalizeAll(),
              description: message,
            );

          case wallet_flutter.XelisWalletOutgoingEntry():
            final message =
                '(#${txType.nonce}) ${loc.outgoing_transaction_confirmed.capitalize()}';
            _emitInfo(title: message);

          case wallet_flutter.XelisWalletCoinbaseEntry():
            final amount = formatXelis(txType.reward, state.network);
            _emitInfo(
              title: '${loc.new_mining_reward.capitalize()}:\n+$amount',
            );

          case wallet_flutter.XelisWalletBurnEntry():
            final message = messageBuilder.burnTransaction(txType);
            _emitEvent(
              title: loc.burn_transaction_confirmed.capitalizeAll(),
              description: message,
            );

          case wallet_flutter.XelisWalletMultisigEntry():
            _emitInfo(
              title:
                  '${loc.multisig_modified_successfully_event} ${event.transaction.topoheight}',
            );

          case wallet_flutter.XelisWalletInvokeContractEntry():
            _emitEvent(
              title: loc.contract_invoked,
              description: txType.contract,
            );

          case wallet_flutter.XelisWalletDeployContractEntry():
            _emitInfo(
              title:
                  '${loc.contract_deployed_at} ${event.transaction.topoheight}',
            );

          case wallet_flutter.XelisWalletIncomingContractEntry():
            _emitInfo(title: 'Contract Transfer Received');

          case wallet_flutter.XelisWalletIncomingBlobEntry() ||
              wallet_flutter.XelisWalletOutgoingBlobEntry():
            _emitEvent(
              title: loc.blob.capitalize(),
              description: '${loc.topoheight}: ${event.transaction.topoheight}',
            );
        }

      case wallet_flutter.XelisWalletNewPendingTransaction():
        logDiagnostic(
          () =>
              'Wallet event: type=NewPendingTransaction '
              'hash=${event.transaction.hash}',
        );
        await _updateMultisigState(context);
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }

        final txType = event.transaction.entry;

        await _ensureKnownAssetsForTransaction(context, txType);
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        final xelisBalance = await repository.getXelisBalance();
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        final updatedBalances = await repository.getTrackedBalances();
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        state = state.copyWith(
          trackedBalances: sortMapByKey(updatedBalances),
          xelisBalance: xelisBalance,
        );
        ref.read(walletHistoryRefreshSignalProvider.notifier).bump();
        await _emitPendingTransactionEvent(context, loc, event.transaction);

      case wallet_flutter.XelisWalletBalanceChanged():
        logDiagnostic(
          () =>
              'Wallet event: type=BalanceChanged '
              'asset=${event.asset} '
              'balance=${event.balance}',
        );
        final xelisBalance = await repository.getXelisBalance();
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        final updatedBalances = await repository.getTrackedBalances();
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        state = state.copyWith(
          trackedBalances: sortMapByKey(updatedBalances),
          xelisBalance: xelisBalance,
        );

      case wallet_flutter.XelisWalletNewAsset():
        logDiagnostic(
          () =>
              'Wallet event: type=NewAsset '
              'asset=${event.asset.assetHash} '
              'topoheight=${event.asset.topoheight}',
        );
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        final updatedAssets =
            LinkedHashMap<String, wallet_flutter.XelisWalletAssetMetadata>.from(
              state.knownAssets,
            );
        updatedAssets[event.asset.assetHash] = event.asset.metadata;
        state = state.copyWith(knownAssets: sortMapByKey(updatedAssets));
        _emitEvent(
          title: loc.new_asset_detected,
          description:
              '${event.asset.metadata.name} - ${event.asset.metadata.ticker}\n${loc.topoheight}: ${event.asset.topoheight}',
        );

      case wallet_flutter.XelisWalletAssetTracked():
        logDiagnostic(
          () => 'Wallet event: type=TrackAsset asset=${event.asset}',
        );
        await _handleTrackAssetEvent(context, loc, event.asset);

      case wallet_flutter.XelisWalletAssetUntracked():
        logDiagnostic(
          () => 'Wallet event: type=UntrackAsset asset=${event.asset}',
        );
        final updatedBalances = await repository.getTrackedBalances();
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        state = state.copyWith(trackedBalances: sortMapByKey(updatedBalances));
        _emitInfo(title: loc.asset_successfully_untracked);

      case wallet_flutter.XelisWalletBusinessEventStreamDegraded():
        _scheduleBusinessReconciliation(
          context,
          failure: event.failure,
          skippedEvents: event.skippedEvents,
          sequence: frame.sequence,
        );

      case wallet_flutter.XelisWalletBusinessEventStreamClosed():
        if (!_claimBusinessEventTermination(context)) {
          return;
        }
        final failure = recordAppFailure(
          event.failure,
          StackTrace.current,
          operation: 'wallet.business_events.stream',
          applicationCode: 'wallet_business_event_stream_closed',
          contextBuilder: () =>
              'generation=${frame.generation} sequence=${frame.sequence}',
        );
        _emitFailure(failure: failure);
    }
  }

  Future<void> _emitPendingTransactionEvent(
    _BusinessEventContext context,
    AppLocalizations loc,
    wallet_flutter.XelisWalletPendingTransaction transactionPending,
  ) async {
    if (!_isCurrentBusinessEventContext(context)) {
      return;
    }

    final txType = transactionPending.entry;
    final title = '${loc.pending} ${loc.transaction}'.capitalize();
    final hashText = '${loc.hash}: ${truncateText(transactionPending.hash)}';
    final messageBuilder = _eventMessageBuilder(loc);

    switch (txType) {
      case wallet_flutter.XelisWalletIncomingEntry():
        final message = await messageBuilder.incomingTransaction(txType);
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        _emitEvent(title: title, description: '$message\n$hashText');

      case wallet_flutter.XelisWalletOutgoingEntry():
        _emitEvent(title: title, description: '(#${txType.nonce})\n$hashText');

      case wallet_flutter.XelisWalletCoinbaseEntry():
        _emitEvent(title: title, description: hashText);

      case wallet_flutter.XelisWalletBurnEntry():
        final message = messageBuilder.burnTransaction(txType);
        _emitEvent(title: title, description: '$message\n$hashText');

      case wallet_flutter.XelisWalletMultisigEntry():
        _emitEvent(title: title, description: hashText);

      case wallet_flutter.XelisWalletInvokeContractEntry():
        _emitEvent(title: title, description: '${txType.contract}\n$hashText');

      case wallet_flutter.XelisWalletDeployContractEntry():
        _emitEvent(title: title, description: hashText);

      case wallet_flutter.XelisWalletIncomingContractEntry():
        _emitEvent(title: title, description: hashText);

      case wallet_flutter.XelisWalletIncomingBlobEntry() ||
          wallet_flutter.XelisWalletOutgoingBlobEntry():
        _emitEvent(title: title, description: hashText);
    }
  }

  Future<void> _handleTrackAssetEvent(
    _BusinessEventContext context,
    AppLocalizations loc,
    String assetHash,
  ) async {
    final repository = context.repository;
    try {
      final assetData = await repository.getAssetMetadata(assetHash);
      if (!_isCurrentBusinessEventContext(context)) {
        return;
      }

      final updatedAssets =
          LinkedHashMap<String, wallet_flutter.XelisWalletAssetMetadata>.from(
            state.knownAssets,
          );
      updatedAssets[assetHash] = assetData;

      final updatedBalances = await repository.getTrackedBalances();
      if (!_isCurrentBusinessEventContext(context)) {
        return;
      }

      state = state.copyWith(
        trackedBalances: sortMapByKey(updatedBalances),
        knownAssets: sortMapByKey(updatedAssets),
      );
    } catch (error) {
      if (!_isCurrentBusinessEventContext(context)) {
        return;
      }
      logDiagnosticError(
        'wallet.asset.metadata',
        error,
        contextBuilder: () => 'asset=$assetHash',
      );
      final updatedBalances = await repository.getTrackedBalances();
      if (!_isCurrentBusinessEventContext(context)) {
        return;
      }
      state = state.copyWith(trackedBalances: sortMapByKey(updatedBalances));
    }

    if (_isCurrentBusinessEventContext(context)) {
      _emitInfo(title: loc.asset_successfully_tracked);
    }
  }

  Future<void> _ensureKnownAssetsForTransaction(
    _BusinessEventContext context,
    wallet_flutter.XelisWalletTransactionEntryData txType,
  ) async {
    final repository = context.repository;
    final fetchedAssets = await WalletTransactionAssetResolver(
      getAssetMetadata: repository.getAssetMetadata,
      hasKnownAsset: (assetHash) => state.knownAssets.containsKey(assetHash),
      isActiveRepository: () => _isCurrentBusinessEventContext(context),
      onFetchError: (assetHash, error) {
        logDiagnosticError(
          'wallet.transaction.asset_metadata',
          error,
          contextBuilder: () => 'asset=$assetHash',
        );
      },
    ).fetchMissingAssets(txType);
    if (fetchedAssets == null || fetchedAssets.isEmpty) {
      return;
    }

    if (!_isCurrentBusinessEventContext(context)) {
      return;
    }

    final updatedAssets =
        LinkedHashMap<String, wallet_flutter.XelisWalletAssetMetadata>.from(
          state.knownAssets,
        );
    updatedAssets.addAll(fetchedAssets);
    state = state.copyWith(knownAssets: sortMapByKey(updatedAssets));
  }

  WalletEventMessageBuilder _eventMessageBuilder(AppLocalizations loc) {
    return WalletEventMessageBuilder(
      loc: loc,
      knownAssets: state.knownAssets,
      contactNameForAddress: _contactNameForAddress,
    );
  }

  Future<String?> _contactNameForAddress(String address) async {
    final addressBook = ref.read(addressBookProvider.notifier);
    final contact = await addressBook.exactEntryForAddress(address);
    return contact?.displayName;
  }

  bool _isCurrentBusinessEventContext(_BusinessEventContext context) {
    return identical(_businessEventContext, context) &&
        !context.invalidated &&
        context.generation == context.subscription.generation &&
        _isActiveRepository(context.repository);
  }

  void _scheduleBusinessReconciliation(
    _BusinessEventContext context, {
    required wallet_flutter.XelisWalletException failure,
    required BigInt skippedEvents,
    required BigInt sequence,
  }) {
    if (!_isCurrentBusinessEventContext(context)) {
      return;
    }
    context.reconciliationPending = true;
    if (context.reconciliationInProgress) {
      return;
    }

    recordAppFailure(
      failure,
      StackTrace.current,
      operation: 'wallet.business_events.stream',
      applicationCode: 'wallet_business_event_stream_lagged',
      contextBuilder: () =>
          'generation=${context.generation} sequence=$sequence '
          'skippedEvents=$skippedEvents',
    );
    context.reconciliationInProgress = true;
    final reconciliation = _runBusinessReconciliation(context);
    context.reconciliationFuture = reconciliation;
    unawaited(reconciliation);
  }

  Future<void> _runBusinessReconciliation(_BusinessEventContext context) async {
    try {
      while (context.reconciliationPending &&
          _isCurrentBusinessEventContext(context)) {
        context.reconciliationPending = false;
        await _hydrateRuntimeState(
          context.repository,
          businessContext: context,
          emitFailure: false,
        );
        if (!_isCurrentBusinessEventContext(context)) {
          return;
        }
        ref.read(walletHistoryRefreshSignalProvider.notifier).bump();
      }
    } finally {
      context.reconciliationInProgress = false;
      context.reconciliationFuture = null;
    }
  }

  bool _claimBusinessEventTermination(_BusinessEventContext context) {
    if (!_isCurrentBusinessEventContext(context) ||
        context.terminationClaimed) {
      return false;
    }
    context.terminationClaimed = true;
    context.invalidated = true;
    return true;
  }

  void _handleBusinessEventStreamError(
    _BusinessEventContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!_claimBusinessEventTermination(context)) {
      return;
    }
    final failure = recordAppFailure(
      error,
      stackTrace,
      operation: 'wallet.business_events.stream',
      applicationCode: 'wallet_business_event_stream_failed',
      contextBuilder: () => 'generation=${context.generation}',
    );
    _emitFailure(failure: failure);
  }

  void _handleBusinessEventStreamDone(_BusinessEventContext context) {
    if (!_claimBusinessEventTermination(context)) {
      return;
    }
    final failure = recordAppFailure(
      StateError('The business wallet event stream closed unexpectedly.'),
      StackTrace.current,
      operation: 'wallet.business_events.stream',
      applicationCode: 'wallet_business_event_stream_closed',
      contextBuilder: () => 'generation=${context.generation}',
    );
    _emitFailure(failure: failure);
  }

  Future<void> _cancelBusinessEventSubscription() {
    final context = _businessEventContext;
    if (context == null) {
      return Future.value();
    }
    final existingCancellation = context.cancellationFuture;
    if (existingCancellation != null) {
      return existingCancellation;
    }

    final cancellation = _cancelBusinessEventContext(
      context,
      awaitConsumerPump: !context.terminationClaimed,
    );
    context.cancellationFuture = cancellation;
    return cancellation;
  }

  Future<void> _cancelBusinessEventContext(
    _BusinessEventContext context, {
    required bool awaitConsumerPump,
  }) async {
    context.invalidated = true;
    context.reconciliationPending = false;
    try {
      Object? listenerCancellationError;
      StackTrace? listenerCancellationStackTrace;
      try {
        await context.iterator.cancel();
      } catch (error, stackTrace) {
        listenerCancellationError = error;
        listenerCancellationStackTrace = stackTrace;
      }

      await context.subscription.cancel();

      final pump = context.pump;
      if (awaitConsumerPump && pump != null) {
        await pump;
      }
      final reconciliation = context.reconciliationFuture;
      if (reconciliation != null) {
        await reconciliation;
      }

      if (identical(_businessEventContext, context)) {
        _businessEventContext = null;
      }
      if (listenerCancellationError != null) {
        logDiagnosticError(
          'wallet.business_events.listener.cancel',
          listenerCancellationError,
          stackTrace: listenerCancellationStackTrace,
        );
      }
    } catch (_) {
      context.cancellationFuture = null;
      rethrow;
    }
  }

  void _invalidateBusinessEventContext() {
    _businessEventContext?.invalidated = true;
  }

  void _invalidateRuntimeEventContext() {
    _runtimeEventContext?.invalidated = true;
  }

  bool _isCurrentRuntimeEventContext(_RuntimeEventContext context) {
    return identical(_runtimeEventContext, context) &&
        !context.invalidated &&
        context.generation == context.subscription.generation &&
        _isCurrentConnectionRequest(context.requestId, context.repository);
  }

  Future<bool> _subscribeRuntimeEvents(
    NativeWalletRepository repository,
    int requestId,
  ) async {
    final subscription = await repository.subscribeRuntimeEvents();
    if (!_isCurrentConnectionRequest(requestId, repository)) {
      await subscription.cancel();
      return false;
    }

    final context = _RuntimeEventContext(
      repository: repository,
      requestId: requestId,
      subscription: subscription,
    );
    _runtimeEventContext = context;
    final pump = _consumeRuntimeEvents(context);
    context.pump = pump;
    unawaited(pump);
    return true;
  }

  Future<void> _consumeRuntimeEvents(_RuntimeEventContext context) async {
    try {
      while (await context.iterator.moveNext()) {
        if (!_isCurrentRuntimeEventContext(context)) {
          return;
        }
        final frame = context.iterator.current;
        if (frame.generation != context.generation) {
          throw StateError('Unexpected wallet runtime event generation.');
        }
        await _onRuntimeEvent(context, frame);
        if (!_isCurrentRuntimeEventContext(context)) {
          return;
        }
      }
      _handleRuntimeEventStreamDone(context);
    } catch (error, stackTrace) {
      _handleRuntimeEventStreamError(context, error, stackTrace);
    } finally {
      if (context.terminationClaimed &&
          identical(_runtimeEventContext, context)) {
        try {
          await _cancelRuntimeEventSubscription();
        } catch (error, stackTrace) {
          logDiagnosticError(
            'wallet.events.terminal_cleanup',
            error,
            stackTrace: stackTrace,
            contextBuilder: () => 'generation=${context.generation}',
          );
        }
      }
    }
  }

  Future<void> _onRuntimeEvent(
    _RuntimeEventContext context,
    wallet_flutter.XelisWalletRuntimeEventFrame frame,
  ) async {
    if (!_isCurrentRuntimeEventContext(context)) {
      return;
    }

    final repository = context.repository;
    final loc = ref.read(appLocalizationsProvider);
    switch (frame.event) {
      case wallet_flutter.XelisWalletOnline():
        logDiagnostic(
          () =>
              'Wallet runtime event: type=Online '
              'generation=${frame.generation} sequence=${frame.sequence}',
        );
        if (_connectionSucceededRequestId != context.requestId ||
            (state.connectionPhase != WalletConnectionPhase.connecting &&
                state.connectionPhase != WalletConnectionPhase.reconnecting)) {
          return;
        }
        _markConnectedState();
        _emitInfo(title: loc.connected);
        await _refreshSyncingState(
          repository,
          requestId: context.requestId,
          runtimeContext: context,
        );

      case wallet_flutter.XelisWalletOffline():
        logDiagnostic(
          () =>
              'Wallet runtime event: type=Offline '
              'generation=${frame.generation} sequence=${frame.sequence}',
        );
        final wasOnline = state.isOnline;
        if (state.connectionPhase == WalletConnectionPhase.connecting ||
            state.connectionPhase == WalletConnectionPhase.reconnecting) {
          _markOfflineDuringConnectionTransition();
          return;
        }
        if (!state.isOnline &&
            (state.connectionPhase == WalletConnectionPhase.disconnected ||
                state.connectionPhase == WalletConnectionPhase.offline)) {
          return;
        }
        _markOfflineEventState();
        _emitInfo(title: loc.disconnected);
        if (wasOnline &&
            isRetryableWalletConnectionFailure(state.lastConnectionFailure)) {
          _scheduleAutoReconnect(repository);
        }

      case wallet_flutter.XelisWalletSyncIssue(:final failure):
        final appFailure = recordAppFailure(
          failure,
          StackTrace.current,
          operation: 'wallet.sync',
          applicationCode: 'wallet_sync_failed',
          contextBuilder: () =>
              'generation=${frame.generation} sequence=${frame.sequence}',
        );
        if (!_isCurrentRuntimeEventContext(context)) {
          return;
        }
        // A sync issue is non-terminal. Only a following typed Offline event
        // controls reconnection.
        _emitConnectionFailure(
          requestId: context.requestId,
          title: loc.error_while_syncing,
          failure: appFailure,
        );

      case wallet_flutter.XelisWalletTopoheightChanged(:final topoheight):
        logDiagnostic(
          () =>
              'Wallet runtime event: type=TopoheightChanged '
              'topoheight=$topoheight generation=${frame.generation} '
              'sequence=${frame.sequence}',
        );
        state = state.copyWith(topoheight: topoheight);

      case wallet_flutter.XelisWalletRescanStarted(:final startTopoheight):
        logDiagnostic(
          () =>
              'Wallet runtime event: type=RescanStarted '
              'startTopoheight=$startTopoheight '
              'generation=${frame.generation} sequence=${frame.sequence}',
        );
        state = state.copyWith(isRescanning: true);

      case wallet_flutter.XelisWalletHistorySynced(:final topoheight):
        logDiagnostic(
          () =>
              'Wallet runtime event: type=HistorySynced '
              'topoheight=$topoheight generation=${frame.generation} '
              'sequence=${frame.sequence}',
        );
        ref.read(walletHistoryRefreshSignalProvider.notifier).bump();
        state = state.copyWith(topoheight: topoheight, isRescanning: false);
        _emitInfo(title: 'History synced');

      case wallet_flutter.XelisWalletEventStreamDegraded(
        :final skippedEvents,
        :final failure,
      ):
        _scheduleRuntimeReconciliation(
          context,
          failure: failure,
          skippedEvents: skippedEvents,
          sequence: frame.sequence,
        );

      case wallet_flutter.XelisWalletEventStreamClosed(:final failure):
        if (!_claimRuntimeEventTermination(context)) {
          return;
        }
        final appFailure = recordAppFailure(
          failure,
          StackTrace.current,
          operation: 'wallet.events.stream',
          applicationCode: 'wallet_event_stream_closed',
          contextBuilder: () =>
              'generation=${frame.generation} sequence=${frame.sequence}',
        );
        _markConnectionFailedState(appFailure);
        _emitConnectionFailure(
          requestId: context.requestId,
          failure: appFailure,
        );
    }
  }

  void _scheduleRuntimeReconciliation(
    _RuntimeEventContext context, {
    required wallet_flutter.XelisWalletException failure,
    required BigInt skippedEvents,
    required BigInt sequence,
  }) {
    if (!_isCurrentRuntimeEventContext(context)) {
      return;
    }
    context.reconciliationPending = true;
    if (context.reconciliationInProgress) {
      return;
    }

    recordAppFailure(
      failure,
      StackTrace.current,
      operation: 'wallet.events.stream',
      applicationCode: 'wallet_event_stream_lagged',
      contextBuilder: () =>
          'generation=${context.generation} sequence=$sequence '
          'skippedEvents=$skippedEvents',
    );
    context.reconciliationInProgress = true;
    final reconciliation = _runRuntimeReconciliation(context);
    context.reconciliationFuture = reconciliation;
    unawaited(reconciliation);
  }

  Future<void> _runRuntimeReconciliation(_RuntimeEventContext context) async {
    try {
      while (context.reconciliationPending &&
          _isCurrentRuntimeEventContext(context)) {
        context.reconciliationPending = false;
        await _hydrateRuntimeState(
          context.repository,
          requestId: context.requestId,
          runtimeContext: context,
          emitFailure: false,
        );
        if (!_isCurrentRuntimeEventContext(context)) {
          return;
        }

        try {
          final daemonInfo = await context.repository.getDaemonInfo();
          if (!_isCurrentRuntimeEventContext(context)) {
            return;
          }
          state = state.copyWith(topoheight: daemonInfo.topoheight);
        } catch (error, stackTrace) {
          if (!_isCurrentRuntimeEventContext(context)) {
            return;
          }
          logDiagnosticError(
            'wallet.events.reconcile.topoheight',
            error,
            stackTrace: stackTrace,
          );
        }

        if (!_isCurrentRuntimeEventContext(context)) {
          return;
        }
        ref.read(walletHistoryRefreshSignalProvider.notifier).bump();
        await _refreshSyncingState(
          context.repository,
          requestId: context.requestId,
          runtimeContext: context,
        );
      }
    } finally {
      context.reconciliationInProgress = false;
      context.reconciliationFuture = null;
    }
  }

  bool _claimRuntimeEventTermination(_RuntimeEventContext context) {
    if (!_isCurrentRuntimeEventContext(context) || context.terminationClaimed) {
      return false;
    }
    context.terminationClaimed = true;
    context.invalidated = true;
    return true;
  }

  void _handleRuntimeEventStreamError(
    _RuntimeEventContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!_claimRuntimeEventTermination(context)) {
      return;
    }
    final failure = recordAppFailure(
      error,
      stackTrace,
      operation: 'wallet.events.stream',
      applicationCode: 'wallet_event_stream_failed',
      contextBuilder: () => 'generation=${context.generation}',
    );
    _markConnectionFailedState(failure);
    _emitConnectionFailure(requestId: context.requestId, failure: failure);
  }

  void _handleRuntimeEventStreamDone(_RuntimeEventContext context) {
    if (!_claimRuntimeEventTermination(context)) {
      return;
    }
    final failure = recordAppFailure(
      StateError('The wallet runtime event stream closed unexpectedly.'),
      StackTrace.current,
      operation: 'wallet.events.stream',
      applicationCode: 'wallet_event_stream_closed',
      contextBuilder: () => 'generation=${context.generation}',
    );
    _markConnectionFailedState(failure);
    _emitConnectionFailure(requestId: context.requestId, failure: failure);
  }

  Future<void> _cancelRuntimeEventSubscription() {
    final context = _runtimeEventContext;
    if (context == null) {
      return Future.value();
    }
    final existingCancellation = context.cancellationFuture;
    if (existingCancellation != null) {
      return existingCancellation;
    }

    final cancellation = _cancelRuntimeEventContext(
      context,
      awaitConsumerPump: !context.terminationClaimed,
    );
    context.cancellationFuture = cancellation;
    return cancellation;
  }

  Future<void> _cancelRuntimeEventContext(
    _RuntimeEventContext context, {
    required bool awaitConsumerPump,
  }) async {
    context.invalidated = true;
    context.reconciliationPending = false;
    try {
      Object? listenerCancellationError;
      StackTrace? listenerCancellationStackTrace;
      try {
        await context.iterator.cancel();
      } catch (error, stackTrace) {
        listenerCancellationError = error;
        listenerCancellationStackTrace = stackTrace;
      }

      // This explicit call is intentionally retained after iterator.cancel().
      // It is idempotent on success and retries a package cancellation if the
      // StreamController's onCancel callback failed before reaching Rust.
      await context.subscription.cancel();

      final pump = context.pump;
      if (awaitConsumerPump && pump != null) {
        await pump;
      }
      final reconciliation = context.reconciliationFuture;
      if (reconciliation != null) {
        await reconciliation;
      }

      if (identical(_runtimeEventContext, context)) {
        _runtimeEventContext = null;
      }
      if (listenerCancellationError != null) {
        logDiagnosticError(
          'wallet.events.listener.cancel',
          listenerCancellationError,
          stackTrace: listenerCancellationStackTrace,
        );
      }
    } catch (_) {
      // Keep the invalidated context reachable so a later lifecycle attempt
      // can retry the native cancellation instead of leaking the opaque handle.
      context.cancellationFuture = null;
      rethrow;
    }
  }

  Future<void> _cancelEventSubscriptions() async {
    Object? runtimeError;
    StackTrace? runtimeStackTrace;
    try {
      await _cancelRuntimeEventSubscription();
    } catch (error, stackTrace) {
      runtimeError = error;
      runtimeStackTrace = stackTrace;
    }

    Object? businessError;
    StackTrace? businessStackTrace;
    try {
      await _cancelBusinessEventSubscription();
    } catch (error, stackTrace) {
      businessError = error;
      businessStackTrace = stackTrace;
    }

    if (runtimeError != null) {
      if (businessError != null) {
        logDiagnosticError(
          'wallet.business_events.cancel',
          businessError,
          stackTrace: businessStackTrace,
        );
      }
      Error.throwWithStackTrace(runtimeError, runtimeStackTrace!);
    }
    if (businessError != null) {
      Error.throwWithStackTrace(businessError, businessStackTrace!);
    }
  }

  void _disposeRuntimeResources() {
    _connectionIntentsBlocked = true;
    _sessionLifecycleId++;
    _connectionRequestId++;
    _invalidateRuntimeEventContext();
    _invalidateBusinessEventContext();
    _connectionSucceededRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    final cleanup = _cancelEventSubscriptions().catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      logDiagnosticError(
        'wallet.events.dispose',
        error,
        stackTrace: stackTrace,
      );
    });
    unawaited(cleanup);
    _repository = null;
  }

  Future<void> _queueConnectionTransition({
    required NodeAddress selectedNode,
    required WalletConnectionPhase phase,
    required bool persistSelection,
    required bool reportFailure,
  }) async {
    if (_connectionIntentsBlocked) {
      return;
    }
    if (ref.read(settingsProvider).walletOfflineMode) {
      await _enterOfflineMode(
        selectedNode: selectedNode,
        persistSelection: persistSelection,
      );
      return;
    }

    final repository = _repository;
    if (repository == null) {
      return;
    }

    final requestId = ++_connectionRequestId;
    _invalidateRuntimeEventContext();
    _connectionSucceededRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();

    if (persistSelection) {
      final settings = ref.read(settingsProvider);
      ref
          .read(networkNodesProvider.notifier)
          .setNodeAddress(settings.network, selectedNode);
    }

    _markConnectionTransitionState(selectedNode: selectedNode, phase: phase);

    await _enqueueTransition(() async {
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }

      final loc = ref.read(appLocalizationsProvider);
      final failureTitle = loc.cannot_connect_toast_error.replaceFirst(
        RegExp(r'\.'),
        '',
      );

      Object? cancellationError;
      StackTrace? cancellationStackTrace;
      try {
        await _cancelRuntimeEventSubscription();
      } catch (error, stackTrace) {
        cancellationError = error;
        cancellationStackTrace = stackTrace;
      }
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }

      try {
        await repository.setOffline();
      } catch (error, stackTrace) {
        _handleConnectionFailure(
          requestId: requestId,
          repository: repository,
          error: error,
          stackTrace: stackTrace,
          operation: 'wallet.network.disconnect',
          applicationCode: 'wallet_network_disconnect_failed',
          title: failureTitle,
          reportFailure: reportFailure,
          // A silent automatic attempt must not permanently stop its own
          // loop when cleanup reports an otherwise retryable failure.
          allowRetry: !reportFailure,
          contextBuilder: () =>
              'endpoint=${sanitizeEndpointForDiagnostics(selectedNode.url)}',
        );
        return;
      }
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }
      if (cancellationError != null) {
        _handleConnectionFailure(
          requestId: requestId,
          repository: repository,
          error: cancellationError,
          stackTrace: cancellationStackTrace!,
          operation: 'wallet.events.cancel',
          applicationCode: 'wallet_event_stream_cancel_failed',
          title: failureTitle,
          reportFailure: reportFailure,
          allowRetry: false,
        );
        return;
      }

      try {
        final subscribed = await _subscribeRuntimeEvents(repository, requestId);
        if (!subscribed) {
          return;
        }
      } catch (error, stackTrace) {
        _handleConnectionFailure(
          requestId: requestId,
          repository: repository,
          error: error,
          stackTrace: stackTrace,
          operation: 'wallet.events.subscribe',
          applicationCode: 'wallet_event_stream_subscribe_failed',
          title: failureTitle,
          reportFailure: reportFailure,
          allowRetry: false,
        );
        return;
      }
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }

      try {
        await repository.setOnline(daemonAddress: selectedNode.url);
        final runtimeContext = _runtimeEventContext;
        if (!_isCurrentConnectionRequest(requestId, repository) ||
            runtimeContext == null ||
            !_isCurrentRuntimeEventContext(runtimeContext)) {
          return;
        }
        _connectionSucceededRequestId = requestId;
        if (state.connectionPhase == WalletConnectionPhase.failed) {
          return;
        }
        await _hydrateRuntimeState(
          repository,
          requestId: requestId,
          runtimeContext: runtimeContext,
          emitFailure: reportFailure,
        );
        await _markConnectedIfOnlineEventWasMissed(runtimeContext, loc);
      } catch (error, stackTrace) {
        _handleConnectionFailure(
          requestId: requestId,
          repository: repository,
          error: error,
          stackTrace: stackTrace,
          operation: 'wallet.network.connect',
          applicationCode: 'wallet_network_connect_failed',
          title: failureTitle,
          reportFailure: reportFailure,
          allowRetry: true,
          contextBuilder: () =>
              'endpoint=${sanitizeEndpointForDiagnostics(selectedNode.url)}',
        );
      }
    });
  }

  void _handleConnectionFailure({
    required int requestId,
    required NativeWalletRepository repository,
    required Object error,
    required StackTrace stackTrace,
    required String operation,
    required String applicationCode,
    required String title,
    required bool reportFailure,
    required bool allowRetry,
    String Function()? contextBuilder,
  }) {
    if (!_isCurrentConnectionRequest(requestId, repository)) {
      return;
    }

    _connectionSucceededRequestId = -1;
    final failure = reportFailure
        ? recordAppFailure(
            error,
            stackTrace,
            operation: operation,
            applicationCode: applicationCode,
            contextBuilder: contextBuilder,
          )
        : appFailureFromError(
            error,
            operation: operation,
            applicationCode: applicationCode,
          );

    if (!reportFailure) {
      logDiagnosticError(
        operation,
        error,
        stackTrace: stackTrace,
        contextBuilder: contextBuilder,
      );
    }

    _markConnectionFailedState(failure);
    if (reportFailure) {
      _emitConnectionFailure(
        requestId: requestId,
        title: title,
        failure: failure,
      );
    }
    if (allowRetry && isRetryableWalletConnectionFailure(failure)) {
      _scheduleAutoReconnect(repository);
    }
  }

  void _scheduleAutoReconnect(NativeWalletRepository repository) {
    if (_connectionIntentsBlocked ||
        ref.read(settingsProvider).walletOfflineMode ||
        !_isActiveRepository(repository) ||
        _autoReconnectTimer != null) {
      return;
    }

    final requestId = _connectionRequestId;
    final selectedNode = state.selectedNode;
    if (selectedNode == null) {
      return;
    }

    _autoReconnectTimer = Timer(_autoReconnectDelay, () {
      _autoReconnectTimer = null;
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }
      if (_connectionIntentsBlocked ||
          ref.read(settingsProvider).walletOfflineMode) {
        return;
      }
      unawaited(
        _queueConnectionTransition(
          selectedNode: selectedNode,
          phase: WalletConnectionPhase.reconnecting,
          persistSelection: false,
          reportFailure: false,
        ),
      );
    });
  }

  void _cancelAutoReconnect() {
    _autoReconnectTimer?.cancel();
    _autoReconnectTimer = null;
  }

  bool _ensureConnectedNodeAvailable() {
    if (state.isOnline &&
        state.connectionPhase == WalletConnectionPhase.connected) {
      return true;
    }

    _emitNodeRequiredWarning();
    return false;
  }

  void _emitNodeRequiredWarning() {
    final loc = ref.read(appLocalizationsProvider);
    final settings = ref.read(settingsProvider);
    final description =
        settings.walletOfflineMode ||
            state.connectionPhase == WalletConnectionPhase.offline
        ? loc.action_not_available_offline
        : state.connectionPhase == WalletConnectionPhase.connecting ||
              state.connectionPhase == WalletConnectionPhase.reconnecting
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

  Future<void> _enqueueTransition(Future<void> Function() action) {
    return _transitionQueue.enqueue(action);
  }

  Future<void> _enterOfflineMode({
    NativeWalletRepository? repository,
    NodeAddress? selectedNode,
    bool persistSelection = false,
  }) async {
    if (_connectionIntentsBlocked) {
      return;
    }
    final activeRepository = repository ?? _repository;
    final requestId = ++_connectionRequestId;
    _invalidateRuntimeEventContext();
    _connectionSucceededRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();

    if (persistSelection && selectedNode != null) {
      final settings = ref.read(settingsProvider);
      ref
          .read(networkNodesProvider.notifier)
          .setNodeAddress(settings.network, selectedNode);
    }

    _markOfflineModeState(selectedNode: selectedNode);

    if (activeRepository == null) {
      await _cancelRuntimeEventSubscription();
      return;
    }

    await _enqueueTransition(() async {
      if (!_isCurrentConnectionRequest(requestId, activeRepository)) {
        return;
      }

      Object? cancellationError;
      StackTrace? cancellationStackTrace;
      try {
        await _cancelRuntimeEventSubscription();
      } catch (error, stackTrace) {
        cancellationError = error;
        cancellationStackTrace = stackTrace;
      }
      if (!_isCurrentConnectionRequest(requestId, activeRepository)) {
        return;
      }

      try {
        await activeRepository.setOffline();
      } catch (error, stackTrace) {
        if (!_isCurrentConnectionRequest(requestId, activeRepository)) {
          return;
        }
        final failure = recordAppFailure(
          error,
          stackTrace,
          operation: 'wallet.network.disconnect',
          applicationCode: 'wallet_network_disconnect_failed',
        );
        _markConnectionFailedState(failure);
        _emitFailure(failure: failure);
        return;
      }
      if (!_isCurrentConnectionRequest(requestId, activeRepository)) {
        return;
      }

      if (cancellationError != null) {
        final failure = recordAppFailure(
          cancellationError,
          cancellationStackTrace!,
          operation: 'wallet.events.cancel',
          applicationCode: 'wallet_event_stream_cancel_failed',
        );
        state = state.copyWith(lastConnectionFailure: failure);
        _emitFailure(failure: failure);
      }

      await _hydrateRuntimeState(activeRepository, requestId: requestId);
    });
  }

  bool _isActiveRepository(NativeWalletRepository repository) {
    return identical(_repository, repository);
  }

  bool _isCurrentSessionLifecycle(int lifecycleId) {
    return lifecycleId == _sessionLifecycleId;
  }

  bool _isCurrentConnectionRequest(
    int requestId,
    NativeWalletRepository repository,
  ) {
    return requestId == _connectionRequestId && _isActiveRepository(repository);
  }

  bool _canApplyRepositoryResult(
    NativeWalletRepository repository, {
    int? requestId,
    _RuntimeEventContext? runtimeContext,
    _BusinessEventContext? businessContext,
  }) {
    if (requestId != null &&
        !_isCurrentConnectionRequest(requestId, repository)) {
      return false;
    }
    if (runtimeContext != null &&
        !_isCurrentRuntimeEventContext(runtimeContext)) {
      return false;
    }
    if (businessContext != null &&
        !_isCurrentBusinessEventContext(businessContext)) {
      return false;
    }
    return _isActiveRepository(repository);
  }

  Future<void> _markConnectedIfOnlineEventWasMissed(
    _RuntimeEventContext context,
    AppLocalizations loc,
  ) async {
    if (!_isCurrentRuntimeEventContext(context) ||
        _connectionSucceededRequestId != context.requestId ||
        (state.connectionPhase != WalletConnectionPhase.connecting &&
            state.connectionPhase != WalletConnectionPhase.reconnecting)) {
      return;
    }

    final nativeOnline = await context.repository.isOnline;
    if (!_isCurrentRuntimeEventContext(context) ||
        _connectionSucceededRequestId != context.requestId ||
        (state.connectionPhase != WalletConnectionPhase.connecting &&
            state.connectionPhase != WalletConnectionPhase.reconnecting)) {
      return;
    }

    if (!nativeOnline) {
      // The native loop can emit SyncIssue -> Offline before setOnline returns.
      // In that case no later Online event can complete this transition.
      _markDisconnectedState(clearError: true);
      _scheduleAutoReconnect(context.repository);
      return;
    }

    _markConnectedState();
    _emitInfo(title: loc.connected);
    await _refreshSyncingState(
      context.repository,
      requestId: context.requestId,
      runtimeContext: context,
    );
  }

  void _emitConnectionFailure({
    required int requestId,
    String? title,
    required AppFailure failure,
  }) {
    if (requestId != _connectionRequestId ||
        _lastReportedConnectionFailureId == requestId) {
      return;
    }
    _lastReportedConnectionFailureId = requestId;
    _emitFailure(title: title, failure: failure);
  }

  NodeAddress _selectedNodeForCurrentNetwork() {
    final settings = ref.read(settingsProvider);
    return _selectedNodeForNetwork(settings.network);
  }

  NodeAddress _selectedNodeForNetwork(wallet_flutter.XelisNetwork network) {
    final nodes = ref.read(networkNodesProvider);
    return nodes.getNodeAddress(network);
  }

  WalletRuntimeState _emptyRuntimeState() {
    return WalletRuntimeState(
      topoheight: BigInt.zero,
      xelisBalance: BigInt.zero,
      trackedBalances: LinkedHashMap.from({}),
      knownAssets: LinkedHashMap.from({}),
    );
  }

  WalletRuntimeState _runtimeStateFromSession(
    WalletSession session,
    NodeAddress selectedNode,
  ) {
    return WalletRuntimeState(
      name: session.name,
      address: session.address,
      network: session.network,
      topoheight: BigInt.zero,
      xelisBalance: BigInt.zero,
      trackedBalances: LinkedHashMap.from({}),
      knownAssets: LinkedHashMap.from({}),
      selectedNode: selectedNode,
    );
  }

  void _emitInfo({required String title}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.info(title: title));
  }

  void _emitFailure({String? title, required AppFailure failure}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.failure(title: title, failure: failure));
  }

  void _emitEvent({String? title, required String description}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.event(title: title, description: description));
  }
}

final class _BusinessEventContext {
  _BusinessEventContext({required this.repository, required this.subscription})
    : generation = subscription.generation,
      iterator = StreamIterator(subscription.events);

  final NativeWalletRepository repository;
  final wallet_flutter.XelisWalletBusinessEventSubscription subscription;
  final BigInt generation;
  final StreamIterator<wallet_flutter.XelisWalletBusinessEventFrame> iterator;

  Future<void>? pump;
  Future<void>? cancellationFuture;
  Future<void>? reconciliationFuture;
  bool invalidated = false;
  bool terminationClaimed = false;
  bool reconciliationInProgress = false;
  bool reconciliationPending = false;
}

final class _RuntimeEventContext {
  _RuntimeEventContext({
    required this.repository,
    required this.requestId,
    required this.subscription,
  }) : generation = subscription.generation,
       iterator = StreamIterator(subscription.events);

  final NativeWalletRepository repository;
  final int requestId;
  final wallet_flutter.XelisWalletRuntimeEventSubscription subscription;
  final BigInt generation;
  final StreamIterator<wallet_flutter.XelisWalletRuntimeEventFrame> iterator;

  Future<void>? pump;
  Future<void>? cancellationFuture;
  Future<void>? reconciliationFuture;
  bool invalidated = false;
  bool terminationClaimed = false;
  bool reconciliationInProgress = false;
  bool reconciliationPending = false;
}

class _SerialAsyncQueue {
  Future<void> _tail = Future.value();

  Future<void> enqueue(Future<void> Function() action) {
    final future = _tail.then((_) => action());
    _tail = future.catchError((_) {});
    return future;
  }
}
