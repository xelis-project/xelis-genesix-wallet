import 'dart:async';
import 'dart:convert';

import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/src/generated/rust_bridge/api/dtos.dart';
import 'package:genesix/src/generated/rust_bridge/api/network.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/features/wallet/domain/event.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/src/generated/rust_bridge/api/wallet.dart';

class NativeWalletRepository {
  NativeWalletRepository._internal(this._xelisWallet);

  final XelisWallet _xelisWallet;

  static Future<NativeWalletRepository> create(
    String walletPath,
    String pwd,
    Network network, {
    String? precomputeTablesPath,
  }) async {
    final xelisWallet = await createXelisWallet(
      name: walletPath,
      password: pwd,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
    );
    talker.info('new XELIS Wallet created: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> recoverFromSeed(
    String walletPath,
    String pwd,
    Network network, {
    required String seed,
    String? precomputeTablesPath,
  }) async {
    final xelisWallet = await createXelisWallet(
      name: walletPath,
      password: pwd,
      seed: seed,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
    );
    talker.info('XELIS Wallet recovered from seed: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> recoverFromPrivateKey(
    String walletPath,
    String pwd,
    Network network, {
    required String privateKey,
    String? precomputeTablesPath,
  }) async {
    final xelisWallet = await createXelisWallet(
      name: walletPath,
      password: pwd,
      privateKey: privateKey,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
    );
    talker.info('XELIS Wallet recovered from private key: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> open(
    String walletPath,
    String pwd,
    Network network, {
    String? precomputeTablesPath,
  }) async {
    final xelisWallet = await openXelisWallet(
      name: walletPath,
      password: pwd,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
    );
    talker.info('XELIS Wallet open: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  Future<void> close() async {
    await _xelisWallet.close();
  }

  void dispose() {
    _xelisWallet.dispose();
    if (_xelisWallet.isDisposed) talker.info('Rust Wallet disposed');
  }

  XelisWallet get nativeWallet => _xelisWallet;

  String get address => _xelisWallet.getAddressStr();

  Future<BigInt> get nonce => _xelisWallet.getNonce();

  Future<bool> get isOnline => _xelisWallet.isOnline();

  Future<void> setOnline({required String daemonAddress}) async {
    await _xelisWallet.onlineMode(daemonAddress: daemonAddress);
    talker.info('XELIS Wallet connected to: $daemonAddress');
  }

  Future<void> setOffline() async {
    await _xelisWallet.offlineMode();
    talker.info('XELIS Wallet offline');
  }

  Stream<Event> convertRawEvents() async* {
    final rawEventStream = _xelisWallet.eventsStream();

    await for (final rawData in rawEventStream) {
      final json = jsonDecode(rawData);
      try {
        final eventType = sdk.WalletEvent.fromStr(json['event'] as String);
        switch (eventType) {
          case sdk.WalletEvent.newTopoHeight:
            final newTopoheight = Event.newTopoheight(
              json['data']['topoheight'] as int,
            );
            yield newTopoheight;
          case sdk.WalletEvent.newAsset:
            final newAsset = Event.newAsset(
              sdk.AssetData.fromJson(json['data'] as Map<String, dynamic>),
            );
            yield newAsset;
          case sdk.WalletEvent.newTransaction:
            final newTransaction = Event.newTransaction(
              sdk.TransactionEntry.fromJson(
                json['data'] as Map<String, dynamic>,
              ),
            );
            yield newTransaction;
          case sdk.WalletEvent.balanceChanged:
            final balanceChanged = Event.balanceChanged(
              sdk.BalanceChangedEvent.fromJson(
                json['data'] as Map<String, dynamic>,
              ),
            );
            yield balanceChanged;
          case sdk.WalletEvent.rescan:
            final rescan = Event.rescan(
              json['data']['start_topoheight'] as int,
            );
            yield rescan;
          case sdk.WalletEvent.online:
            yield const Event.online();
          case sdk.WalletEvent.offline:
            yield const Event.offline();
          case sdk.WalletEvent.historySynced:
            final historySynced = Event.historySynced(
              json['data']['topoheight'] as int,
            );
            yield historySynced;
        }
      } catch (e) {
        talker.error('Unknown event: ${json['event']}');
        continue;
      }
    }
  }

  Future<String> formatCoin(int amount, [String? assetHash]) async {
    return _xelisWallet.formatCoin(
      atomicAmount: BigInt.from(amount),
      assetHash: assetHash,
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return _xelisWallet.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<String> getSeed({int? languageIndex}) async {
    return _xelisWallet.getSeed(
      languageIndex: languageIndex == null ? null : BigInt.from(languageIndex),
    );
  }

  Future<void> isValidPassword(String password) async {
    return _xelisWallet.isValidPassword(password: password);
  }

  Future<String> getXelisBalance() async {
    return _xelisWallet.getXelisBalance();
  }

  Future<bool> hasXelisBalance() async {
    return _xelisWallet.hasXelisBalance();
  }

  Future<Map<String, String>> getAssetBalances() async {
    return _xelisWallet.getAssetBalances();
  }

  Future<int> getHistoryCount() async {
    final count = await _xelisWallet.getHistoryCount();
    if (count.isValidInt) {
      return count.toInt();
    } else {
      throw Exception('Invalid history count');
    }
  }

  Future<List<sdk.TransactionEntry>> history(HistoryPageFilter filter) async {
    final rawData = await _xelisWallet.history(filter: filter);
    return rawData
        .map((e) => jsonDecode(e))
        .map(
          (entry) =>
              sdk.TransactionEntry.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }

  Future<sdk.GetInfoResult> getDaemonInfo() async {
    final rawData = await _xelisWallet.getDaemonInfo();
    final json = jsonDecode(rawData);
    return sdk.GetInfoResult.fromJson(json as Map<String, dynamic>);
  }

  Future<void> rescan({required int topoheight}) async {
    return _xelisWallet.rescan(topoheight: BigInt.from(topoheight));
  }

  Future<String> estimateFees(
    List<Transfer> transfers,
    double? feeMultiplier,
  ) async {
    return _xelisWallet.estimateFees(
      transfers: transfers,
      feeMultiplier: feeMultiplier,
    );
  }

  Future<TransactionSummary> createTransferTransaction({
    double? amount,
    required String address,
    required String assetHash,
    double? feeMultiplier,
  }) async {
    String rawTx;
    if (amount != null) {
      rawTx = await _xelisWallet.createTransfersTransaction(
        transfers: [
          Transfer(
            floatAmount: amount,
            strAddress: address,
            assetHash: assetHash,
          ),
        ],
        feeMultiplier: feeMultiplier,
      );
    } else {
      rawTx = await _xelisWallet.createTransferAllTransaction(
        strAddress: address,
        assetHash: assetHash,
        feeMultiplier: feeMultiplier,
      );
    }
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<String> createMultisigTransferTransaction({
    double? amount,
    required String address,
    required String assetHash,
    double? feeMultiplier,
  }) async {
    if (amount != null) {
      return _xelisWallet.createMultisigTransfersTransaction(
        transfers: [
          Transfer(
            floatAmount: amount,
            strAddress: address,
            assetHash: assetHash,
          ),
        ],
        feeMultiplier: feeMultiplier,
      );
    } else {
      return _xelisWallet.createMultisigTransferAllTransaction(
        strAddress: address,
        assetHash: assetHash,
        feeMultiplier: feeMultiplier,
      );
    }
  }

  Future<TransactionSummary> createTransfersTransaction(
    List<Transfer> transfers,
  ) async {
    final rawTx = await _xelisWallet.createTransfersTransaction(
      transfers: transfers,
    );
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<String> createMultisigTransfersTransaction(
    List<Transfer> transfers,
  ) async {
    return _xelisWallet.createMultisigTransfersTransaction(
      transfers: transfers,
    );
  }

  Future<TransactionSummary> createBurnTransaction({
    double? amount,
    required String assetHash,
  }) async {
    String rawTx;
    if (amount == null) {
      rawTx = await _xelisWallet.createBurnAllTransaction(assetHash: assetHash);
    } else {
      rawTx = await _xelisWallet.createBurnTransaction(
        floatAmount: amount,
        assetHash: assetHash,
      );
    }
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<String> createMultisigBurnTransaction({
    double? amount,
    required String assetHash,
  }) async {
    if (amount == null) {
      return await _xelisWallet.createMultisigBurnAllTransaction(
        assetHash: assetHash,
      );
    } else {
      return await _xelisWallet.createMultisigBurnTransaction(
        floatAmount: amount,
        assetHash: assetHash,
      );
    }
  }

  Future<void> broadcastTransaction(String hash) async {
    await _xelisWallet.broadcastTransaction(txHash: hash);
    talker.info('Transaction successfully broadcast: $hash');
  }

  Future<void> clearTransaction(String hash) async {
    await _xelisWallet.clearTransaction(txHash: hash);
    talker.info('Transaction canceled: $hash');
  }

  Future<MultisigState?> getMultisigState() async {
    final rawData = await _xelisWallet.getMultisigState();
    switch (rawData) {
      case String():
        final json = jsonDecode(rawData) as Map<String, dynamic>;
        return MultisigState.fromJson(json);
      case null:
        return null;
    }
  }

  Future<String> signTransactionHash(String txHash) async {
    return _xelisWallet.multisigSign(txHash: txHash);
  }

  Future<TransactionSummary?> setupMultisig({
    required List<String> participants,
    required int threshold,
  }) async {
    final rawTx = await _xelisWallet.multisigSetup(
      threshold: threshold,
      participants: participants,
    );
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  bool isAddressValidForMultisig(String address) {
    return _xelisWallet.isAddressValidForMultisig(address: address);
  }

  Future<String> initDeleteMultisig() async {
    return _xelisWallet.initDeleteMultisig();
  }

  Future<TransactionSummary?> finalizeMultisigTransaction({
    required List<SignatureMultisig> signatures,
  }) async {
    final rawTx = await _xelisWallet.finalizeMultisigTransaction(
      signatures: signatures,
    );
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<void> exportTransactionsToCsvFile(String path) async {
    await _xelisWallet.exportTransactionsToCsvFile(filePath: path);
  }

  Future<String> convertTransactionsToCsv() async {
    return _xelisWallet.convertTransactionsToCsv();
  }
}
