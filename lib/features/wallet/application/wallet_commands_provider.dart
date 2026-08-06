import 'package:flutter/foundation.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/biometric_wallet_key.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/prepared_transaction_broadcast_policy.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_node_action_guard.dart';
import 'package:genesix/features/wallet/application/wallet_password_change_coordinator.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_password_change_result.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

part 'wallet_commands_provider.g.dart';

@Riverpod(keepAlive: true)
WalletCommandsController walletCommands(Ref ref) {
  return WalletCommandsController(ref);
}

class WalletCommandsController {
  const WalletCommandsController(this.ref);

  final Ref ref;

  Future<
    (
      wallet_flutter.XelisWalletPreparedTransaction?,
      wallet_flutter.XelisWalletMultisigSigningRequest?,
    )
  >
  send({
    required BigInt amountAtomic,
    required String destination,
    required String asset,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState != null) {
        final signingRequest = await repository
            .createMultisigTransferTransaction(
              amountAtomic: amountAtomic,
              address: destination,
              assetHash: asset,
              feePolicy: feePolicy,
            );
        if (!_isRepositoryActive(repository)) {
          await _cancelStaleMultisigRequest(repository, signingRequest);
          return (null, null);
        }
        return (null, signingRequest);
      }

      final prepared = await repository.prepareTransferTransaction(
        amountAtomic: amountAtomic,
        address: destination,
        assetHash: asset,
        feePolicy: feePolicy,
      );
      if (!_isRepositoryActive(repository)) {
        await _discardStalePrepared(repository, prepared);
        return (null, null);
      }
      return (prepared, null);
    } catch (error, stackTrace) {
      if (!_isRepositoryActive(repository)) return (null, null);
      _emitStructuredCommandError(
        title: 'Cannot create transaction',
        operation: 'wallet.transaction.transfers.prepare',
        applicationCode: 'transaction_prepare_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return (null, null);
  }

  Future<
    (
      wallet_flutter.XelisWalletPreparedTransaction?,
      wallet_flutter.XelisWalletMultisigSigningRequest?,
    )
  >
  sendAll({
    required String destination,
    required String asset,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState != null) {
        final signingRequest = await repository
            .createMultisigTransferTransaction(
              address: destination,
              assetHash: asset,
              feePolicy: feePolicy,
            );
        if (!_isRepositoryActive(repository)) {
          await _cancelStaleMultisigRequest(repository, signingRequest);
          return (null, null);
        }
        return (null, signingRequest);
      }

      final prepared = await repository.prepareTransferAll(
        address: destination,
        assetHash: asset,
        feePolicy: feePolicy,
      );
      if (!_isRepositoryActive(repository)) {
        await _discardStalePrepared(repository, prepared);
        return (null, null);
      }
      return (prepared, null);
    } catch (error, stackTrace) {
      if (!_isRepositoryActive(repository)) return (null, null);
      _emitStructuredCommandError(
        title: 'Cannot create transaction',
        operation: 'wallet.transaction.transfer_all.prepare',
        applicationCode: 'transaction_prepare_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return (null, null);
  }

  Future<
    (
      wallet_flutter.XelisWalletPreparedTransaction?,
      wallet_flutter.XelisWalletMultisigSigningRequest?,
    )
  >
  burn({
    required BigInt amountAtomic,
    required String asset,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState != null) {
        final signingRequest = await repository.createMultisigBurnTransaction(
          amountAtomic: amountAtomic,
          assetHash: asset,
          feePolicy: feePolicy,
        );
        if (!_isRepositoryActive(repository)) {
          await _cancelStaleMultisigRequest(repository, signingRequest);
          return (null, null);
        }
        return (null, signingRequest);
      }

      final prepared = await repository.prepareBurnTransaction(
        amountAtomic: amountAtomic,
        assetHash: asset,
        feePolicy: feePolicy,
      );
      if (!_isRepositoryActive(repository)) {
        await _discardStalePrepared(repository, prepared);
        return (null, null);
      }
      return (prepared, null);
    } catch (error, stackTrace) {
      if (!_isRepositoryActive(repository)) return (null, null);
      _emitStructuredCommandError(
        title: 'Cannot create transaction',
        operation: 'wallet.transaction.burn.prepare',
        applicationCode: 'transaction_prepare_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return (null, null);
  }

  Future<
    (
      wallet_flutter.XelisWalletPreparedTransaction?,
      wallet_flutter.XelisWalletMultisigSigningRequest?,
    )
  >
  burnAll({
    required String asset,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState != null) {
        final signingRequest = await repository.createMultisigBurnTransaction(
          assetHash: asset,
          feePolicy: feePolicy,
        );
        if (!_isRepositoryActive(repository)) {
          await _cancelStaleMultisigRequest(repository, signingRequest);
          return (null, null);
        }
        return (null, signingRequest);
      }

      final prepared = await repository.prepareBurnAll(
        assetHash: asset,
        feePolicy: feePolicy,
      );
      if (!_isRepositoryActive(repository)) {
        await _discardStalePrepared(repository, prepared);
        return (null, null);
      }
      return (prepared, null);
    } catch (error, stackTrace) {
      if (!_isRepositoryActive(repository)) return (null, null);
      _emitStructuredCommandError(
        title: 'Cannot create transaction',
        operation: 'wallet.transaction.burn_all.prepare',
        applicationCode: 'transaction_prepare_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return (null, null);
  }

  Future<bool> cancelPreparedTransaction({
    required wallet_flutter.XelisWalletPreparedTransaction transaction,
    required Object sessionIdentity,
  }) async {
    if (sessionIdentity is! NativeWalletRepository) return false;
    final repository = sessionIdentity;

    try {
      await repository.discardPreparedTransaction(transaction);
      return true;
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot cancel transaction',
        operation: 'wallet.transaction.prepared.cancel',
        applicationCode: 'prepared_transaction_cancel_failed',
        error: error,
        stackTrace: stackTrace,
        contextBuilder: () => 'transactionHash=${transaction.hash}',
      );
      return false;
    }
  }

  Future<PreparedTransactionBroadcastResult?> broadcastPreparedTx({
    required wallet_flutter.XelisWalletPreparedTransaction transaction,
    required Object sessionIdentity,
  }) async {
    if (sessionIdentity is! NativeWalletRepository) {
      return null;
    }
    final repository = sessionIdentity;
    if (!_isRepositoryActive(repository)) return null;
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      final packageResult = await repository.broadcastPreparedTransaction(
        transaction,
      );
      final result = projectPreparedTransactionBroadcastResult(
        packageResult,
        recordFailure: (failure) =>
            _recordPreparedBroadcastFailure(failure, transaction),
      );
      if (!_isRepositoryActive(repository)) return null;
      return reconcilePreparedTransactionBroadcastResult(
        result,
        rescan: () => ref.read(walletRuntimeProvider.notifier).rescan(),
        onRescanFailure: (error, stackTrace) {
          _emitStructuredCommandError(
            title: 'Rescan failed',
            operation: 'wallet.rescan',
            applicationCode: 'wallet_rescan_failed',
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot broadcast transaction',
        operation: 'wallet.transaction.broadcast',
        applicationCode: 'transaction_broadcast_failed',
        error: error,
        stackTrace: stackTrace,
        contextBuilder: () => 'transactionHash=${transaction.hash}',
      );
      return null;
    }
  }

  Future<BigInt> estimateFees({
    required BigInt amountAtomic,
    required String destination,
    required String asset,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return BigInt.zero;
    }
    if (!_nodeActionGuard.ensureNodeAvailable(notify: false)) {
      return BigInt.zero;
    }

    try {
      return repository.estimateTransferFees([
        wallet_flutter.XelisWalletTransferRequest(
          destination: destination,
          asset: asset,
          amountAtomic: amountAtomic,
        ),
      ], feePolicy: feePolicy);
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot estimate transaction fees',
        operation: 'wallet.transaction.fees.estimate',
        applicationCode: 'transaction_fee_estimate_failed',
        error: error,
        stackTrace: stackTrace,
      );
      return BigInt.zero;
    }
  }

  Future<void> exportCsv(
    String directoryPath,
    wallet_flutter.XelisWalletHistoryFilter filter,
  ) async {
    final repository = _repository;
    if (repository == null) {
      throw StateError('No active wallet session.');
    }
    await repository.exportTransactionsToCsvFile(
      p.join(directoryPath, 'genesix_transactions.csv'),
      filter,
    );
  }

  Future<String> exportCsvForWeb(
    wallet_flutter.XelisWalletHistoryFilter filter,
  ) async {
    final repository = _repository;
    if (repository == null) {
      throw StateError('No active wallet session.');
    }
    return repository.convertTransactionsToCsv(filter);
  }

  Future<WalletPasswordChangeResult> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final session = ref.read(activeWalletSessionProvider);
    if (session == null) {
      final failure = recordAppFailure(
        StateError('No active wallet session.'),
        StackTrace.current,
        operation: 'wallet.password.change',
        applicationCode: 'wallet_session_missing',
        applicationCategory: AppFailureCategory.operationFailure,
      );
      return WalletPasswordChangeFailure(failure);
    }

    final secureStorage = kIsWeb ? null : ref.read(secureStorageProvider);
    final passwordKey = walletPasswordKey(
      network: session.network,
      walletName: session.name,
    );
    final biometricKey = biometricWalletKey(
      network: session.network,
      walletName: session.name,
    );
    bool isCapturedSessionActive() {
      final activeSession = ref.read(activeWalletSessionProvider);
      return activeSession != null &&
          identical(activeSession.repository, session.repository) &&
          activeSession.name == session.name &&
          activeSession.network == session.network;
    }

    return WalletPasswordChangeCoordinator(
      synchronizeBiometricCredential: !kIsWeb,
      changeNativePassword: (oldValue, newValue) => session.repository
          .changePassword(oldPassword: oldValue, newPassword: newValue),
      isBiometricCredentialEnabled: () async {
        if (!isCapturedSessionActive()) {
          throw StateError('The active wallet session changed.');
        }
        return secureStorage!.containsKey(key: biometricKey);
      },
      persistBiometricCredential: (password) async {
        if (!isCapturedSessionActive() ||
            !await secureStorage!.containsKey(key: biometricKey)) {
          throw StateError('Biometric credential synchronization changed.');
        }

        await secureStorage.write(key: passwordKey, value: password);

        if (!isCapturedSessionActive() ||
            !await secureStorage.containsKey(key: biometricKey)) {
          await secureStorage.delete(key: passwordKey);
          throw StateError('Biometric credential synchronization changed.');
        }
      },
      disableBiometricCredential: () => ref
          .read(settingsProvider.notifier)
          .disableBiometricAuthForWallet(
            network: session.network,
            walletName: session.name,
            updateActiveSettings: isCapturedSessionActive(),
          ),
    ).change(oldPassword: oldPassword, newPassword: newPassword);
  }

  Future<List<String>> getSeed(MnemonicLanguage language) async {
    final repository = _repository;
    if (repository == null) {
      return [];
    }

    final seed = await repository.getSeed(language: language.seedLanguage);
    return seed.split(' ');
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction?> setupMultisig({
    required List<String> participants,
    required int threshold,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      final prepared = await repository.setupMultisig(
        participants: participants,
        threshold: threshold,
      );
      if (!_isRepositoryActive(repository)) {
        await _discardStalePrepared(repository, prepared);
        return null;
      }
      return prepared;
    } catch (error, stackTrace) {
      if (!_isRepositoryActive(repository)) return null;
      _emitStructuredCommandError(
        title: 'Cannot setup multisig',
        operation: 'wallet.multisig.setup.prepare',
        applicationCode: 'multisig_setup_prepare_failed',
        error: error,
        stackTrace: stackTrace,
        contextBuilder: () =>
            'threshold=$threshold participantCount=${participants.length}',
      );
    }

    return null;
  }

  bool isAddressValidForMultisig(String address) {
    final repository = _repository;
    if (repository == null) {
      return false;
    }
    return repository.isAddressValidForMultisig(address);
  }

  Future<wallet_flutter.XelisWalletMultisigSigningRequest?>
  startDeleteMultisig() async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      final request = await repository.initDeleteMultisig();
      if (!_isRepositoryActive(repository)) {
        await _cancelStaleMultisigRequest(repository, request);
        return null;
      }
      return request;
    } catch (error, stackTrace) {
      if (!_isRepositoryActive(repository)) return null;
      _emitStructuredCommandError(
        title: 'Cannot start delete multisig',
        operation: 'wallet.multisig.delete.prepare',
        applicationCode: 'multisig_delete_prepare_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction?>
  finalizeMultisigTransaction({
    required wallet_flutter.XelisWalletMultisigSigningRequest request,
    required List<wallet_flutter.XelisWalletMultisigSignatureShare> shares,
    required Object sessionIdentity,
  }) async {
    if (sessionIdentity is! NativeWalletRepository) {
      return null;
    }
    final repository = sessionIdentity;
    if (!_isRepositoryActive(repository)) return null;

    try {
      final prepared = await repository.finalizeMultisigTransaction(
        request: request,
        shares: shares,
      );
      if (!_isRepositoryActive(repository)) {
        await _discardStalePrepared(repository, prepared);
        return null;
      }
      return prepared;
    } catch (error, stackTrace) {
      if (!_isRepositoryActive(repository)) return null;
      _emitStructuredCommandError(
        title: 'Cannot finalize multisig transaction',
        operation: 'wallet.multisig.finalize',
        applicationCode: 'multisig_finalize_failed',
        error: error,
        stackTrace: stackTrace,
        contextBuilder: () =>
            'signingHash=${request.signingHash} shareCount=${shares.length}',
      );
    }

    return null;
  }

  Future<bool> cancelPendingMultisigRequest({
    required wallet_flutter.XelisWalletMultisigSigningRequest request,
    required Object sessionIdentity,
  }) async {
    if (sessionIdentity is! NativeWalletRepository) {
      return false;
    }
    final repository = sessionIdentity;

    try {
      await repository.cancelPendingMultisigRequest(request);
      return true;
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot cancel multisig request',
        operation: 'wallet.multisig.request.cancel',
        applicationCode: 'multisig_request_cancel_failed',
        error: error,
        stackTrace: stackTrace,
        contextBuilder: () => 'signingHash=${request.signingHash}',
      );
    }

    return false;
  }

  Future<wallet_flutter.XelisWalletMultisigSigningRequest?>
  inspectMultisigSigningRequest(String encoded) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      return await repository.inspectMultisigSigningRequest(encoded);
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot inspect multisig request',
        operation: 'wallet.multisig.request.inspect',
        applicationCode: 'multisig_request_inspect_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<wallet_flutter.XelisWalletMultisigSignatureShare?>
  signMultisigSigningRequest(
    wallet_flutter.XelisWalletMultisigSigningRequest request,
  ) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      return await repository.signMultisigSigningRequest(request);
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot sign multisig request',
        operation: 'wallet.multisig.request.sign',
        applicationCode: 'multisig_request_sign_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<wallet_flutter.XelisWalletMultisigSignatureShare?>
  inspectMultisigSignatureShare({
    required wallet_flutter.XelisWalletMultisigSigningRequest request,
    required String encoded,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }

    try {
      return await repository.inspectMultisigSignatureShare(
        request: request,
        encoded: encoded,
      );
    } catch (error, stackTrace) {
      // Invalid clipboard input is rendered as a field error. Do not log the
      // raw share. Preserve the structured failure for support diagnostics.
      recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.multisig.share.inspect',
        applicationCode: 'multisig_share_inspect_failed',
        contextBuilder: () => 'signingHash=${request.signingHash}',
      );
      return null;
    }
  }

  Future<void> trackAsset(String assetHash) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return;
    }

    try {
      await repository.trackAsset(assetHash);
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot track asset',
        operation: 'wallet.asset.track',
        applicationCode: 'asset_track_failed',
        error: error,
        stackTrace: stackTrace,
        contextBuilder: () => 'asset=$assetHash',
      );
    }
  }

  Future<void> untrackAsset(String assetHash) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    try {
      await repository.untrackAsset(assetHash);
    } catch (error, stackTrace) {
      _emitStructuredCommandError(
        title: 'Cannot untrack asset',
        operation: 'wallet.asset.untrack',
        applicationCode: 'asset_untrack_failed',
        error: error,
        stackTrace: stackTrace,
        contextBuilder: () => 'asset=$assetHash',
      );
    }
  }

  NativeWalletRepository? get _repository {
    return ref.read(activeWalletRepositoryProvider);
  }

  bool _isRepositoryActive(NativeWalletRepository repository) {
    return identical(_repository, repository);
  }

  Future<void> _discardStalePrepared(
    NativeWalletRepository repository,
    wallet_flutter.XelisWalletPreparedTransaction transaction,
  ) async {
    try {
      await repository.discardPreparedTransaction(transaction);
    } catch (error, stackTrace) {
      recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.transaction.prepared.stale_discard',
        applicationCode: 'prepared_transaction_stale_discard_failed',
        contextBuilder: () => 'transactionHash=${transaction.hash}',
      );
    }
  }

  Future<void> _cancelStaleMultisigRequest(
    NativeWalletRepository repository,
    wallet_flutter.XelisWalletMultisigSigningRequest request,
  ) async {
    try {
      await repository.cancelPendingMultisigRequest(request);
    } catch (error, stackTrace) {
      recordAppFailure(
        error,
        stackTrace,
        operation: 'wallet.multisig.request.stale_cancel',
        applicationCode: 'multisig_request_stale_cancel_failed',
        contextBuilder: () => 'signingHash=${request.signingHash}',
      );
    }
  }

  WalletRuntimeState get _runtimeState {
    return ref.read(walletRuntimeProvider);
  }

  WalletNodeActionGuard get _nodeActionGuard {
    return WalletNodeActionGuard(ref);
  }

  AppFailure _recordPreparedBroadcastFailure(
    wallet_flutter.XelisWalletException failure,
    wallet_flutter.XelisWalletPreparedTransaction transaction,
  ) {
    return recordAppFailure(
      failure,
      StackTrace.current,
      operation: 'wallet.transaction.broadcast',
      applicationCode: 'transaction_broadcast_failed',
      contextBuilder: () => 'transactionHash=${transaction.hash}',
    );
  }

  void _emitStructuredCommandError({
    required String title,
    required String operation,
    required String applicationCode,
    required Object error,
    required StackTrace stackTrace,
    String Function()? contextBuilder,
  }) {
    final failure = recordAppFailure(
      error,
      stackTrace,
      operation: operation,
      applicationCode: applicationCode,
      contextBuilder: contextBuilder,
    );
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.failure(title: title, failure: failure));
  }
}
