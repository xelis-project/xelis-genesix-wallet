import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:genesix/features/authentication/application/secure_storage_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/mnemonic_languages.dart';
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

  Future<(TransactionSummary?, String?)> send({
    required double amount,
    required String destination,
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final transactionHash = await repository
            .createMultisigTransferTransaction(
              amount: amount,
              address: destination,
              assetHash: asset,
            );
        return (null, transactionHash);
      }

      final transactionSummary = await repository.createTransferTransaction(
        amount: amount,
        address: destination,
        assetHash: asset,
      );
      return (transactionSummary, null);
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot create transaction: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: error.toString(),
        logMessage: 'Cannot create transaction: $error',
      );
    }

    return (null, null);
  }

  Future<(TransactionSummary?, String?)> sendAll({
    required String destination,
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final transactionHash = await repository
            .createMultisigTransferTransaction(
              address: destination,
              assetHash: asset,
            );
        return (null, transactionHash);
      }

      final transactionSummary = await repository.createTransferTransaction(
        address: destination,
        assetHash: asset,
      );
      return (transactionSummary, null);
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot create transaction: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: error.toString(),
        logMessage: 'Cannot create transaction: $error',
      );
    }

    return (null, null);
  }

  Future<(TransactionSummary?, String?)> burn({
    required double amount,
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final transactionHash = await repository.createMultisigBurnTransaction(
          amount: amount,
          assetHash: asset,
        );
        return (null, transactionHash);
      }

      final transactionSummary = await repository.createBurnTransaction(
        amount: amount,
        assetHash: asset,
      );
      return (transactionSummary, null);
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot create transaction: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: error.toString(),
        logMessage: 'Cannot create transaction: $error',
      );
    }

    return (null, null);
  }

  Future<(TransactionSummary?, String?)> burnAll({
    required String asset,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return (null, null);
    }

    try {
      if (_runtimeState.multisigState.isSetup) {
        final transactionHash = await repository.createMultisigBurnTransaction(
          assetHash: asset,
        );
        return (null, transactionHash);
      }

      final transactionSummary = await repository.createBurnTransaction(
        assetHash: asset,
      );
      return (transactionSummary, null);
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot create transaction: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot create transaction',
        description: error.toString(),
        logMessage: 'Cannot create transaction: $error',
      );
    }

    return (null, null);
  }

  Future<void> cancelTransaction({required String hash}) async {
    final repository = _repository;
    if (repository != null) {
      await repository.clearTransaction(hash);
    }
  }

  Future<void> broadcastTx({required String hash}) async {
    final repository = _repository;
    if (repository != null) {
      await repository.broadcastTransaction(hash);
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
      await ref
          .read(secureStorageProvider)
          .write(key: _runtimeState.name, value: newPassword);
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

    try {
      return await repository.setupMultisig(
        participants: participants,
        threshold: threshold,
      );
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot setup multisig',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot setup multisig: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot setup multisig',
        description: error.toString(),
        logMessage: 'Cannot setup multisig: $error',
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

  Future<String?> startDeleteMultisig() async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }

    try {
      return await repository.initDeleteMultisig();
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot start delete multisig',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot start delete multisig: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot start delete multisig',
        description: error.toString(),
        logMessage: 'Cannot start delete multisig: $error',
      );
    }

    return null;
  }

  Future<TransactionSummary?> finalizeMultisigTransaction({
    required List<SignatureMultisig> signatures,
  }) async {
    final repository = _repository;
    if (repository == null) {
      return null;
    }

    try {
      return await repository.finalizeMultisigTransaction(
        signatures: signatures,
      );
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot finalize delete multisig',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot finalize delete multisig: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot finalize delete multisig',
        description: error.toString(),
        logMessage: 'Cannot finalize delete multisig: $error',
      );
    }

    return null;
  }

  Future<String> signTransactionHash(String transactionHash) async {
    final repository = _repository;
    if (repository == null) {
      return '';
    }

    try {
      return await repository.signTransactionHash(transactionHash);
    } on AnyhowException catch (error) {
      _emitCommandError(
        title: 'Cannot sign transaction',
        description: _extractXelisMessage(error),
        logMessage: 'Cannot sign transaction: $error',
      );
    } catch (error) {
      _emitCommandError(
        title: 'Cannot sign transaction',
        description: error.toString(),
        logMessage: 'Cannot sign transaction: $error',
      );
    }

    return '';
  }

  Future<void> trackAsset(String assetHash) async {
    final repository = _repository;
    if (repository == null) {
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

  String _extractXelisMessage(AnyhowException error) {
    return error.message.split('\n').first;
  }
}
