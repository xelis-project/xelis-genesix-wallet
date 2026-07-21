import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/biometric_wallet_key.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_node_action_guard.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/shared/resources/app_resources.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';

part 'wallet_commands_provider.g.dart';

@Riverpod(keepAlive: true)
WalletCommandsController walletCommands(Ref ref) {
  return WalletCommandsController(ref);
}

class WalletCommandsController {
  const WalletCommandsController(this.ref);

  final Ref ref;

  Future<(TransactionSummary?, MultisigSigningRequest?)> send({
    required double amount,
    required String destination,
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final signingRequest = await repository
            .createMultisigTransferTransaction(
              amount: amount,
              address: destination,
              assetHash: asset,
            );
        return (null, signingRequest);
      }

      final transactionSummary = await repository.createTransferTransaction(
        amount: amount,
        address: destination,
        assetHash: asset,
      );
      return (transactionSummary, null);
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot create transaction');
    }

    return (null, null);
  }

  Future<(TransactionSummary?, MultisigSigningRequest?)> sendAll({
    required String destination,
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final signingRequest = await repository
            .createMultisigTransferTransaction(
              address: destination,
              assetHash: asset,
            );
        return (null, signingRequest);
      }

      final transactionSummary = await repository.createTransferTransaction(
        address: destination,
        assetHash: asset,
      );
      return (transactionSummary, null);
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot create transaction');
    }

    return (null, null);
  }

  Future<(TransactionSummary?, MultisigSigningRequest?)> burn({
    required double amount,
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final signingRequest = await repository.createMultisigBurnTransaction(
          amount: amount,
          assetHash: asset,
        );
        return (null, signingRequest);
      }

      final transactionSummary = await repository.createBurnTransaction(
        amount: amount,
        assetHash: asset,
      );
      return (transactionSummary, null);
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot create transaction');
    }

    return (null, null);
  }

  Future<(TransactionSummary?, MultisigSigningRequest?)> burnAll({
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final signingRequest = await repository.createMultisigBurnTransaction(
          assetHash: asset,
        );
        return (null, signingRequest);
      }

      final transactionSummary = await repository.createBurnTransaction(
        assetHash: asset,
      );
      return (transactionSummary, null);
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot create transaction');
    }

    return (null, null);
  }

  Future<bool> cancelTransaction({required String hash}) async {
    final repository = _repository;
    if (repository == null) return false;

    try {
      await repository.clearTransaction(hash);
      return true;
    } catch (error) {
      talker.warning('Cannot clear pending transaction: $error');
      return false;
    }
  }

  Future<TransactionBroadcastResult?> broadcastTx({
    required String hash,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      final result = await repository.broadcastTransaction(hash);
      if (result == TransactionBroadcastResult.submittedNeedsResync) {
        await ref.read(walletRuntimeProvider.notifier).rescan();
      }
      return result;
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot broadcast transaction');
      return null;
    }
  }

  Future<String> estimateFees({
    required double amount,
    required String destination,
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return AppResources.zeroBalance;
    }
    if (!_nodeActionGuard.ensureNodeAvailable(notify: false)) {
      return AppResources.zeroBalance;
    }

    return repository.estimateFees([
      Transfer(floatAmount: amount, strAddress: destination, assetHash: asset),
    ]);
  }

  Future<void> exportCsv(String path, HistoryPageFilter filter) async {
    final repository = _repository;
    if (repository != null) {
      await repository.exportTransactionsToCsvFile(
        '$path/genesix_transactions.csv',
        filter,
      );
    }
  }

  Future<String?> exportCsvForWeb(HistoryPageFilter filter) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    return repository.convertTransactionsToCsv(filter);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    await repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (!kIsWeb) {
      final runtimeState = _runtimeState;
      await ref
          .read(secureStorageProvider)
          .write(
            key: walletPasswordKey(
              network: runtimeState.network,
              walletName: runtimeState.name,
            ),
            value: newPassword,
          );
    }
  }

  Future<List<String>> getSeed(MnemonicLanguage language) async {
    final repository = _repository;
    if (repository == null) {
      return [];
    }

    final seed = await repository.getSeed(languageIndex: language.rustIndex);
    return seed.split(' ');
  }

  Future<TransactionSummary?> setupMultisig({
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
      return await repository.setupMultisig(
        participants: participants,
        threshold: threshold,
      );
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot setup multisig');
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

  Future<MultisigSigningRequest?> startDeleteMultisig() async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      return await repository.initDeleteMultisig();
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot start delete multisig');
    }

    return null;
  }

  Future<TransactionSummary?> finalizeMultisigTransaction({
    required String txHash,
    required List<String> signatureShares,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }

    try {
      return await repository.finalizeMultisigTransaction(
        txHash: txHash,
        signatureShares: signatureShares,
      );
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot finalize multisig transaction');
    }

    return null;
  }

  String? getPendingMultisigRequestHash() {
    return _repository?.getPendingMultisigRequestHash();
  }

  Future<bool> cancelPendingMultisigRequest({required String txHash}) async {
    final repository = _repository;
    if (repository == null) {
      return false;
    }

    try {
      repository.cancelPendingMultisigRequest(txHash);
      return true;
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot cancel multisig request');
    }

    return false;
  }

  Future<MultisigSigningRequest?> inspectMultisigSigningRequest(
    String encoded,
  ) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      return await repository.inspectMultisigSigningRequest(encoded);
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot inspect multisig request');
    }

    return null;
  }

  Future<MultisigSignatureShare?> signMultisigSigningRequest(
    String encoded,
  ) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }
    if (!_nodeActionGuard.ensureNodeAvailable()) {
      return null;
    }

    try {
      return await repository.signMultisigSigningRequest(encoded);
    } catch (_) {
      _emitGenericCommandError(title: 'Cannot sign multisig request');
    }

    return null;
  }

  Future<MultisigSignatureShare?> inspectMultisigSignatureShare({
    required String txHash,
    required String encoded,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }

    try {
      return await repository.inspectMultisigSignatureShare(
        txHash: txHash,
        encoded: encoded,
      );
    } catch (_) {
      // Invalid clipboard input is rendered as a field error. Do not log the
      // raw share or emit a global wallet error for this expected failure.
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
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot track asset',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot track asset: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot track asset',
        description: error.toString(),
        logMessage: 'Cannot track asset: $error',
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
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot untrack asset',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot untrack asset: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot untrack asset',
        description: error.toString(),
        logMessage: 'Cannot untrack asset: $error',
      );
    }
  }

  NativeWalletRepository? get _repository {
    return ref.read(activeWalletRepositoryProvider);
  }

  WalletRuntimeState get _runtimeState {
    return ref.read(walletRuntimeProvider);
  }

  WalletNodeActionGuard get _nodeActionGuard {
    return WalletNodeActionGuard(ref);
  }

  void _emitCommandError({
    required String title,
    required String description,
    required String logMessage,
  }) {
    talker.error(logMessage);
    ref
        .read(walletEffectBusProvider.notifier)
        .emit(WalletEffect.error(title: title, description: description));
  }

  void _emitGenericCommandError({required String title}) {
    _emitCommandError(
      title: title,
      description: 'The request could not be completed.',
      logMessage: title,
    );
  }

  String _extractXelisMessage(AnyhowException error) {
    return error.message.split('\n').first;
  }
}
