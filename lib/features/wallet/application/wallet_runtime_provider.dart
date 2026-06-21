import 'dart:async';
import 'dart:collection';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/address_book_provider.dart';
import 'package:genesix/features/wallet/application/network_nodes_provider.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/event.dart';
import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/domain/node_address.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart'
    as rust;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;

import 'wallet_history_refresh_signal_provider.dart';

part 'wallet_runtime_provider.g.dart';

@Riverpod(keepAlive: true)
class WalletRuntime extends _$WalletRuntime {
  static const _autoReconnectDelay = Duration(seconds: 5);
  static const _networkMismatchMessage = 'network mismatch';

  NativeWalletRepository? _repository;
  StreamSubscription<Event>? _streamSubscription;
  Timer? _autoReconnectTimer;
  final _transitionQueue = _SerialAsyncQueue();
  final _eventQueue = _SerialAsyncQueue(
    onError: (error, stackTrace) {
      talker.error('Unhandled wallet event handler error', error, stackTrace);
    },
  );
  int _connectionRequestId = 0;
  int _onlineEligibleRequestId = -1;
  int _lastReportedConnectionFailureId = -1;

  @override
  WalletRuntimeState build() {
    ref.onDispose(_disposeRuntimeResources);
    return _emptyRuntimeState();
  }

  Future<void> attachSession(WalletSession session) async {
    if (identical(_repository, session.repository) &&
        state.name == session.name) {
      return;
    }

    _connectionRequestId++;
    _onlineEligibleRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    await _cancelStreamSubscription();

    _repository = session.repository;
    state = _runtimeStateFromSession(
      session,
      _selectedNodeForNetwork(session.network),
    );
    _streamSubscription = session.repository.convertRawEvents().listen(
      (event) {
        unawaited(_enqueueEvent(() => _onEvent(session.repository, event)));
      },
      onError: (Object error, StackTrace stackTrace) {
        talker.error('Unhandled wallet event stream error', error, stackTrace);
        _emitError(description: error.toString());
      },
    );

    unawaited(connect());
  }

  Future<void> clearSession() async {
    _connectionRequestId++;
    _onlineEligibleRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    await _cancelStreamSubscription();
    _repository = null;
    state = _emptyRuntimeState();
  }

  Future<void> connect() async {
    final selectedNode = _selectedNodeForCurrentNetwork();
    await _queueConnectionTransition(
      selectedNode: selectedNode,
      phase: WalletConnectionPhase.connecting,
      persistSelection: false,
      reportFailure: true,
    );
  }

  Future<void> disconnect() async {
    final requestId = ++_connectionRequestId;
    _onlineEligibleRequestId = -1;
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
      await _setOfflineBestEffort(repository);
    });
  }

  Future<void> prepareForClose() async {
    final requestId = ++_connectionRequestId;
    _onlineEligibleRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    _markDisconnectedState(clearError: true);

    await _enqueueTransition(() async {
      final repository = _repository;
      if (repository == null ||
          !_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }
      await _setOfflineBestEffort(repository);
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
      lastConnectionError: clearError ? null : state.lastConnectionError,
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
      lastConnectionError: null,
    );
  }

  void _markConnectedState() {
    state = state.copyWith(
      isOnline: true,
      connectionPhase: WalletConnectionPhase.connected,
      lastConnectionError: null,
    );
    _lastReportedConnectionFailureId = -1;
  }

  void _markOfflineEventState() {
    state = state.copyWith(
      isOnline: false,
      isSyncing: false,
      connectionPhase: state.connectionPhase == WalletConnectionPhase.failed
          ? WalletConnectionPhase.failed
          : WalletConnectionPhase.disconnected,
    );
  }

  void _markOfflineDuringConnectionTransition() {
    state = state.copyWith(isOnline: false, isSyncing: false);
  }

  void _markConnectionFailedState(String message) {
    state = state.copyWith(
      isOnline: false,
      isSyncing: false,
      connectionPhase: WalletConnectionPhase.failed,
      lastConnectionError: message,
    );
  }

  Future<void> reconnect([NodeAddress? nodeAddress]) async {
    final selectedNode = nodeAddress ?? _selectedNodeForCurrentNetwork();
    final phase = switch (state.connectionPhase) {
      WalletConnectionPhase.connected => WalletConnectionPhase.reconnecting,
      WalletConnectionPhase.connecting => WalletConnectionPhase.reconnecting,
      WalletConnectionPhase.reconnecting => WalletConnectionPhase.reconnecting,
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
    final repository = _repository;
    if (repository == null) {
      return;
    }

    try {
      await repository.rescan(topoheight: 0);
      if (_isActiveRepository(repository)) {
        state = state.copyWith(isRescanning: true);
      }
    } on AnyhowException catch (error) {
      talker.error('Rescan failed: $error');
      _emitError(
        title: 'Rescan failed',
        description: _extractXelisMessage(error),
      );
    } catch (error) {
      talker.error('Rescan failed: $error');
      _emitError(title: 'Rescan failed', description: error.toString());
    }
  }

  Future<void> _updateMultisigState() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final multisig = await repository.getMultisigState();
    final needsUpdate =
        (state.multisigState.isSetup && multisig == null) ||
        (!state.multisigState.isSetup && multisig != null);
    if (needsUpdate && _isActiveRepository(repository)) {
      state = state.copyWith(multisigState: multisig ?? MultisigState());
    }
  }

  Future<void> _hydrateRuntimeState(
    NativeWalletRepository repository, {
    int? requestId,
  }) async {
    try {
      final multisig = await repository.getMultisigState();
      if (!_canApplyRepositoryResult(repository, requestId)) {
        return;
      }

      final xelisBalance = await repository.getXelisBalance();
      if (!_canApplyRepositoryResult(repository, requestId)) {
        return;
      }

      final balances = await repository.getTrackedBalances();
      if (!_canApplyRepositoryResult(repository, requestId)) {
        return;
      }

      final knownAssets = await repository.getKnownAssets();
      if (!_canApplyRepositoryResult(repository, requestId)) {
        return;
      }

      state = state.copyWith(
        multisigState: multisig ?? MultisigState(),
        xelisBalance: formatXelis(xelisBalance, state.network),
        trackedBalances: sortMapByKey(balances),
        knownAssets: sortMapByKey(knownAssets),
      );
    } catch (error) {
      if (!_canApplyRepositoryResult(repository, requestId)) {
        return;
      }
      talker.error('Cannot retrieve wallet data: $error');
      _emitError(description: error.toString());
    }
  }

  Future<void> _onEvent(NativeWalletRepository repository, Event event) async {
    if (!_isActiveRepository(repository)) {
      return;
    }

    final loc = ref.read(appLocalizationsProvider);
    final isSyncing = await repository.isSyncing;
    if (!_isActiveRepository(repository)) {
      return;
    }

    state = state.copyWith(
      isSyncing: state.connectionPhase == WalletConnectionPhase.failed
          ? false
          : isSyncing,
    );

    switch (event) {
      case NewTopoHeight():
        talker.info(event);
        state = state.copyWith(topoheight: event.topoheight);

      case NewTransaction():
        talker.info(event);
        await _updateMultisigState();

        final txType = event.transactionEntry.txEntryType;

        await _ensureKnownAssetsForTransaction(repository, txType);
        ref.read(walletHistoryRefreshSignalProvider.notifier).bump();

        switch (txType) {
          case sdk.IncomingEntry():
            final message = await _buildIncomingTransactionMessage(
              loc: loc,
              txType: txType,
            );
            _emitEvent(
              title: loc.new_incoming_transaction.capitalizeAll(),
              description: message,
            );

          case sdk.OutgoingEntry():
            final message =
                '(#${txType.nonce}) ${loc.outgoing_transaction_confirmed.capitalize()}';
            _emitInfo(title: message);

          case sdk.CoinbaseEntry():
            final amount = formatXelis(txType.reward, state.network);
            _emitInfo(
              title: '${loc.new_mining_reward.capitalize()}:\n+$amount',
            );

          case sdk.BurnEntry():
            final message = _buildBurnTransactionMessage(loc, txType);
            _emitEvent(
              title: loc.burn_transaction_confirmed.capitalizeAll(),
              description: message,
            );

          case sdk.MultisigEntry():
            _emitInfo(
              title:
                  '${loc.multisig_modified_successfully_event} ${event.transactionEntry.topoheight}',
            );

          case sdk.InvokeContractEntry():
            _emitEvent(
              title: loc.contract_invoked,
              description: txType.contract,
            );

          case sdk.DeployContractEntry():
            _emitInfo(
              title:
                  '${loc.contract_deployed_at} ${event.transactionEntry.topoheight}',
            );

          case sdk.IncomingContractEntry():
            _emitInfo(title: 'Contract Transfer Received');

          case sdk.BlobEntry():
            _emitEvent(
              title: loc.blob.capitalize(),
              description:
                  '${loc.topoheight}: ${event.transactionEntry.topoheight}',
            );
        }
      // }

      case BalanceChanged():
        talker.info(event);
        final xelisBalance = await repository.getXelisBalance();
        if (!_isActiveRepository(repository)) {
          return;
        }
        final updatedBalances = await repository.getTrackedBalances();
        if (!_isActiveRepository(repository)) {
          return;
        }
        state = state.copyWith(
          trackedBalances: sortMapByKey(updatedBalances),
          xelisBalance: formatXelis(xelisBalance, state.network),
        );

      case NewAsset():
        talker.info(event);
        final updatedAssets = LinkedHashMap<String, sdk.AssetData>.from(
          state.knownAssets,
        );
        updatedAssets[event.rpcAssetData.asset] = sdk.AssetData(
          decimals: event.rpcAssetData.decimals,
          name: event.rpcAssetData.name,
          ticker: event.rpcAssetData.ticker,
          maxSupply: event.rpcAssetData.maxSupply,
          owner: event.rpcAssetData.owner,
        );
        state = state.copyWith(knownAssets: sortMapByKey(updatedAssets));
        _emitEvent(
          title: loc.new_asset_detected,
          description:
              '${event.rpcAssetData.name} - ${event.rpcAssetData.ticker}\n${loc.topoheight}: ${event.rpcAssetData.topoheight}',
        );

      case Rescan():
        talker.info(event);

      case Online():
        talker.info(event);
        if (_shouldIgnoreTransitionEvent()) {
          return;
        }
        _markConnectedState();
        _emitInfo(title: loc.connected);

      case Offline():
        talker.info(event);
        if (_shouldIgnoreTransitionEvent()) {
          return;
        }
        final wasOnline = state.isOnline;
        if (state.connectionPhase == WalletConnectionPhase.connecting ||
            state.connectionPhase == WalletConnectionPhase.reconnecting) {
          _markOfflineDuringConnectionTransition();
          return;
        }
        if (!state.isOnline &&
            state.connectionPhase == WalletConnectionPhase.disconnected) {
          return;
        }
        _markOfflineEventState();
        _emitInfo(title: loc.disconnected);
        if (wasOnline &&
            _isRetryableConnectionError(state.lastConnectionError)) {
          _scheduleAutoReconnect(repository);
        }

      case HistorySynced():
        talker.info(event);
        ref.read(walletHistoryRefreshSignalProvider.notifier).bump();
        state = state.copyWith(isRescanning: false);
        _emitInfo(title: 'History synced');

      case SyncError():
        talker.error(event);
        if (_shouldIgnoreTransitionEvent()) {
          return;
        }
        _markConnectionFailedState(event.message);
        _emitConnectionFailure(
          requestId: _connectionRequestId,
          title: loc.error_while_syncing,
          description: event.message,
        );
        if (_isRetryableConnectionError(event.message)) {
          _scheduleAutoReconnect(repository);
        }

      case TrackAsset():
        talker.info(event);
        await _handleTrackAssetEvent(repository, loc, event.asset);

      case UntrackAsset():
        talker.info(event);
        final updatedBalances = await repository.getTrackedBalances();
        if (!_isActiveRepository(repository)) {
          return;
        }
        state = state.copyWith(trackedBalances: sortMapByKey(updatedBalances));
        _emitInfo(title: loc.asset_successfully_untracked);
    }
  }

  Future<void> _handleTrackAssetEvent(
    NativeWalletRepository repository,
    AppLocalizations loc,
    String assetHash,
  ) async {
    try {
      final assetData = await repository.getAssetMetadata(assetHash);
      if (!_isActiveRepository(repository)) {
        return;
      }

      final updatedAssets = LinkedHashMap<String, sdk.AssetData>.from(
        state.knownAssets,
      );
      updatedAssets[assetHash] = assetData;

      final updatedBalances = await repository.getTrackedBalances();
      if (!_isActiveRepository(repository)) {
        return;
      }

      state = state.copyWith(
        trackedBalances: sortMapByKey(updatedBalances),
        knownAssets: sortMapByKey(updatedAssets),
      );
    } catch (error) {
      talker.error('Failed to fetch asset metadata for $assetHash: $error');
      final updatedBalances = await repository.getTrackedBalances();
      if (!_isActiveRepository(repository)) {
        return;
      }
      state = state.copyWith(trackedBalances: sortMapByKey(updatedBalances));
    }

    _emitInfo(title: loc.asset_successfully_tracked);
  }

  Future<void> _ensureKnownAssetsForTransaction(
    NativeWalletRepository repository,
    sdk.TransactionEntryType txType,
  ) async {
    final assetHashes = _assetHashesFromTransaction(txType);
    if (assetHashes.isEmpty) {
      return;
    }

    final missingAssets = assetHashes
        .where((assetHash) => !state.knownAssets.containsKey(assetHash))
        .toSet();
    if (missingAssets.isEmpty) {
      return;
    }

    final fetchedAssets = <String, sdk.AssetData>{};
    for (final assetHash in missingAssets) {
      if (state.knownAssets.containsKey(assetHash)) {
        continue;
      }

      try {
        final assetData = await repository.getAssetMetadata(assetHash);
        if (!_isActiveRepository(repository)) {
          return;
        }
        fetchedAssets[assetHash] = assetData;
      } catch (error) {
        if (!_isActiveRepository(repository)) {
          return;
        }
        talker.warning(
          'Failed to fetch asset metadata for transaction asset $assetHash: $error',
        );
      }
    }

    if (fetchedAssets.isEmpty) {
      return;
    }

    final updatedAssets = LinkedHashMap<String, sdk.AssetData>.from(
      state.knownAssets,
    );
    updatedAssets.addAll(fetchedAssets);
    state = state.copyWith(knownAssets: sortMapByKey(updatedAssets));
  }

  Set<String> _assetHashesFromTransaction(sdk.TransactionEntryType txType) {
    return switch (txType) {
      sdk.IncomingEntry() =>
        txType.transfers.map((transfer) => transfer.asset).toSet(),
      sdk.OutgoingEntry() =>
        txType.transfers.map((transfer) => transfer.asset).toSet(),
      sdk.BurnEntry() => {txType.asset},
      sdk.InvokeContractEntry() => {
        ...txType.deposits.keys,
        ...txType.received.keys,
      },
      sdk.DeployContractEntry(invoke: final invoke) => {
        if (invoke != null) ...invoke.deposits.keys,
      },
      sdk.IncomingContractEntry() => txType.transfers.keys.toSet(),
      sdk.CoinbaseEntry() ||
      sdk.MultisigEntry() ||
      sdk.BlobEntry() => const <String>{},
    };
  }

  Future<String> _buildIncomingTransactionMessage({
    required AppLocalizations loc,
    required sdk.IncomingEntry txType,
  }) async {
    if (txType.isMultiTransfer()) {
      return loc.multiple_transfers_detected;
    }

    final atomicAmount = txType.transfers.first.amount;
    final assetHash = txType.transfers.first.asset;

    String asset;
    String amount;
    if (state.knownAssets.containsKey(assetHash)) {
      asset = state.knownAssets[assetHash]!.name;
      amount = formatCoin(
        atomicAmount,
        state.knownAssets[assetHash]!.decimals,
        state.knownAssets[assetHash]!.ticker,
      );
    } else {
      asset = truncateText(assetHash);
      amount = atomicAmount.toString();
    }

    var from = truncateText(txType.from);
    final contactExists = await ref
        .read(addressBookProvider.notifier)
        .exists(txType.from);
    if (contactExists) {
      final contactDetails = await ref
          .read(addressBookProvider.notifier)
          .get(txType.from);
      if (contactDetails != null && contactDetails.name.isNotEmpty) {
        from = contactDetails.name;
      }
    }

    return '${loc.asset}: $asset\n${loc.amount}: +$amount\n${loc.from}: $from';
  }

  String _buildBurnTransactionMessage(
    AppLocalizations loc,
    sdk.BurnEntry txType,
  ) {
    String asset;
    String amount;
    if (state.knownAssets.containsKey(txType.asset)) {
      asset = state.knownAssets[txType.asset]!.name;
      amount = formatCoin(
        txType.amount,
        state.knownAssets[txType.asset]!.decimals,
        state.knownAssets[txType.asset]!.ticker,
      );
    } else {
      asset = truncateText(txType.asset);
      amount = txType.amount.toString();
    }

    return '${loc.asset}: $asset\n${loc.amount}: -$amount';
  }

  Future<void> _cancelStreamSubscription() async {
    final currentSubscription = _streamSubscription;
    _streamSubscription = null;
    await currentSubscription?.cancel();
  }

  void _disposeRuntimeResources() {
    _connectionRequestId++;
    _onlineEligibleRequestId = -1;
    _lastReportedConnectionFailureId = -1;
    _cancelAutoReconnect();
    unawaited(_cancelStreamSubscription());
    _repository = null;
  }

  Future<void> _queueConnectionTransition({
    required NodeAddress selectedNode,
    required WalletConnectionPhase phase,
    required bool persistSelection,
    required bool reportFailure,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    final requestId = ++_connectionRequestId;
    _onlineEligibleRequestId = -1;
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

      await _setOfflineBestEffort(repository);
      if (!_isCurrentConnectionRequest(requestId, repository)) {
        return;
      }

      try {
        _onlineEligibleRequestId = requestId;
        await repository.setOnline(daemonAddress: selectedNode.url);
        if (!_isCurrentConnectionRequest(requestId, repository)) {
          return;
        }
        await _hydrateRuntimeState(repository, requestId: requestId);
        _markConnectedIfOnlineEventWasMissed(requestId, repository, loc);
      } on AnyhowException catch (error) {
        if (!_isCurrentConnectionRequest(requestId, repository)) {
          return;
        }
        _onlineEligibleRequestId = -1;
        talker.warning('Cannot connect to network: ${error.message}');
        final message = _extractXelisMessage(error);
        _markConnectionFailedState(message);
        if (reportFailure) {
          _emitConnectionFailure(
            requestId: requestId,
            title: loc.cannot_connect_toast_error.replaceFirst(
              RegExp(r'\.'),
              '',
            ),
            description: message,
          );
        }
        if (_isRetryableConnectionError(message)) {
          _scheduleAutoReconnect(repository);
        }
      } catch (error) {
        if (!_isCurrentConnectionRequest(requestId, repository)) {
          return;
        }
        _onlineEligibleRequestId = -1;
        talker.warning('Cannot connect to network: $error');
        final message = error.toString();
        _markConnectionFailedState(message);
        if (reportFailure) {
          _emitConnectionFailure(
            requestId: requestId,
            title: loc.cannot_connect_toast_error.replaceFirst(
              RegExp(r'\.'),
              '',
            ),
            description: message,
          );
        }
        if (_isRetryableConnectionError(message)) {
          _scheduleAutoReconnect(repository);
        }
      }
    });
  }

  void _scheduleAutoReconnect(NativeWalletRepository repository) {
    if (!_isActiveRepository(repository) || _autoReconnectTimer != null) {
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

  bool _isRetryableConnectionError(String? message) {
    return message?.toLowerCase().contains(_networkMismatchMessage) != true;
  }

  Future<void> _enqueueTransition(Future<void> Function() action) {
    return _transitionQueue.enqueue(action);
  }

  Future<void> _enqueueEvent(Future<void> Function() action) {
    return _eventQueue.enqueue(action);
  }

  Future<void> _setOfflineBestEffort(NativeWalletRepository repository) async {
    try {
      await repository.setOffline();
    } catch (_) {
      // The wallet may already be offline or have no active network handler.
    }
  }

  bool _isActiveRepository(NativeWalletRepository repository) {
    return identical(_repository, repository);
  }

  bool _isCurrentConnectionRequest(
    int requestId,
    NativeWalletRepository repository,
  ) {
    return requestId == _connectionRequestId && _isActiveRepository(repository);
  }

  bool _canApplyRepositoryResult(
    NativeWalletRepository repository,
    int? requestId,
  ) {
    if (requestId != null &&
        !_isCurrentConnectionRequest(requestId, repository)) {
      return false;
    }
    return _isActiveRepository(repository);
  }

  bool _shouldIgnoreTransitionEvent() {
    return _onlineEligibleRequestId != _connectionRequestId;
  }

  void _markConnectedIfOnlineEventWasMissed(
    int requestId,
    NativeWalletRepository repository,
    AppLocalizations loc,
  ) {
    if (!_isCurrentConnectionRequest(requestId, repository) ||
        state.connectionPhase == WalletConnectionPhase.connected) {
      return;
    }

    _markConnectedState();
    _emitInfo(title: loc.connected);
  }

  void _emitConnectionFailure({
    required int requestId,
    String? title,
    required String description,
  }) {
    if (requestId != _connectionRequestId ||
        _lastReportedConnectionFailureId == requestId) {
      return;
    }
    _lastReportedConnectionFailureId = requestId;
    _emitError(title: title, description: description);
  }

  NodeAddress _selectedNodeForCurrentNetwork() {
    final settings = ref.read(settingsProvider);
    return _selectedNodeForNetwork(settings.network);
  }

  NodeAddress _selectedNodeForNetwork(rust.Network network) {
    final nodes = ref.read(networkNodesProvider);
    return nodes.getNodeAddress(network);
  }

  WalletRuntimeState _emptyRuntimeState() {
    return WalletRuntimeState(
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
      trackedBalances: LinkedHashMap.from({}),
      knownAssets: LinkedHashMap.from({}),
      selectedNode: selectedNode,
    );
  }

  String _extractXelisMessage(AnyhowException error) {
    return error.message.split('\n').first;
  }

  void _emitInfo({required String title}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.info(title: title));
  }

  void _emitError({String? title, required String description}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.error(title: title, description: description));
  }

  void _emitEvent({String? title, required String description}) {
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.event(title: title, description: description));
  }
}

extension TransactionUtils on sdk.TransactionEntryType {
  bool isMultiTransfer() {
    if (this is sdk.IncomingEntry) {
      return (this as sdk.IncomingEntry).transfers.length > 1;
    } else if (this is sdk.OutgoingEntry) {
      return (this as sdk.OutgoingEntry).transfers.length > 1;
    } else {
      return false;
    }
  }
}

class _SerialAsyncQueue {
  _SerialAsyncQueue({this.onError});

  final void Function(Object error, StackTrace stackTrace)? onError;
  Future<void> _tail = Future.value();

  Future<void> enqueue(Future<void> Function() action) {
    final future = _tail.then((_) => action());
    _tail = future.catchError((Object error, StackTrace stackTrace) {
      onError?.call(error, stackTrace);
    });
    return future;
  }
}
