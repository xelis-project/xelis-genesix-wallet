import 'dart:async';
import 'dart:convert';

import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/rust_bridge/api/network.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/features/wallet/domain/event.dart';
import 'package:genesix/shared/logger.dart';
import 'package:genesix/rust_bridge/api/wallet.dart';

class NativeWalletRepository {
  NativeWalletRepository._internal(this._xelisWallet);

  final XelisWallet _xelisWallet;

  static Future<NativeWalletRepository> create(
      String walletPath, String pwd, Network network,
      {String? precomputeTablesPath}) async {
    final xelisWallet = await createXelisWallet(
        name: walletPath,
        password: pwd,
        network: network,
        precomputedTablesPath: precomputeTablesPath);
    logger.info('new XELIS Wallet created: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> recover(
      String walletPath, String pwd, Network network,
      {required String seed, String? precomputeTablesPath}) async {
    final xelisWallet = await createXelisWallet(
        name: walletPath,
        password: pwd,
        seed: seed,
        network: network,
        precomputedTablesPath: precomputeTablesPath);
    logger.info('XELIS Wallet recovered from seed: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> open(
      String walletPath, String pwd, Network network,
      {String? precomputeTablesPath}) async {
    final xelisWallet = await openXelisWallet(
        name: walletPath,
        password: pwd,
        network: network,
        precomputedTablesPath: precomputeTablesPath);
    logger.info('XELIS Wallet open: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  Future<void> close() async {
    await _xelisWallet.close();
  }

  void dispose() {
    _xelisWallet.dispose();
    if (_xelisWallet.isDisposed) logger.info('Rust Wallet disposed');
  }

  XelisWallet get nativeWallet => _xelisWallet;

  String get address => _xelisWallet.getAddressStr();

  Future<BigInt> get nonce => _xelisWallet.getNonce();

  Future<bool> get isOnline => _xelisWallet.isOnline();

  Future<String> formatCoin(int amount, [String? assetHash]) async {
    return _xelisWallet.formatCoin(
        atomicAmount: BigInt.from(amount), assetHash: assetHash);
  }

  Future<void> changePassword(
      {required String oldPassword, required String newPassword}) async {
    return _xelisWallet.changePassword(
        oldPassword: oldPassword, newPassword: newPassword);
  }

  Future<String> getSeed({int? languageIndex}) async {
    return _xelisWallet.getSeed(
        languageIndex:
            languageIndex == null ? null : BigInt.from(languageIndex));
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

  Future<void> rescan({required int topoHeight}) async {
    return _xelisWallet.rescan(topoheight: BigInt.from(topoHeight));
  }

  Future<BigInt> estimateFees(List<Transfer> transfers) async {
    return _xelisWallet.estimateFees(transfers: transfers);
  }

  Future<TransactionSummary> createSimpleTransferTransaction(
      {double? amount, required String address, String? assetHash}) async {
    String rawTx;
    if (amount != null) {
      rawTx = await _xelisWallet.createTransfersTransaction(transfers: [
        Transfer(floatAmount: amount, strAddress: address, assetHash: assetHash)
      ]);
    } else {
      rawTx = await _xelisWallet.createTransferAllTransaction(
          strAddress: address, assetHash: assetHash);
    }
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<TransactionSummary> createMultiTransferTransaction(
      List<Transfer> transfers) async {
    final rawTx =
        await _xelisWallet.createTransfersTransaction(transfers: transfers);
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<TransactionSummary> createBurnTransaction(
      {double? amount, required String assetHash}) async {
    String rawTx;
    if (amount == null) {
      rawTx = await _xelisWallet.createBurnAllTransaction(assetHash: assetHash);
    } else {
      rawTx = await _xelisWallet.createBurnTransaction(
          floatAmount: amount, assetHash: assetHash);
    }
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<void> broadcastTransaction(String hash) async {
    await _xelisWallet.broadcastTransaction(txHash: hash);
    logger.info('Transaction successfully broadcast: $hash');
  }

  Future<void> clearTransaction(String hash) async {
    await _xelisWallet.clearTransaction(txHash: hash);
    logger.info('Transaction canceled: $hash');
  }

  Future<List<sdk.TransactionEntry>> allHistory() async {
    var jsonTransactionsList = await _xelisWallet.allHistory();
    return jsonTransactionsList
        .map((e) => jsonDecode(e))
        .map((entry) =>
            sdk.TransactionEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> setOnline({required String daemonAddress}) async {
    await _xelisWallet.onlineMode(daemonAddress: daemonAddress);
    logger.info('XELIS Wallet connected to: $daemonAddress');
  }

  Future<void> setOffline() async {
    await _xelisWallet.offlineMode();
    logger.info('XELIS Wallet offline');
  }

  Future<sdk.GetInfoResult> getDaemonInfo() async {
    var rawData = await _xelisWallet.getDaemonInfo();
    final json = jsonDecode(rawData);
    return sdk.GetInfoResult.fromJson(json as Map<String, dynamic>);
  }

  Stream<Event> convertRawEvents() async* {
    final rawEventStream = _xelisWallet.eventsStream();

    await for (final rawData in rawEventStream) {
      final json = jsonDecode(rawData);
      final eventType = sdk.WalletEvent.fromStr(json['event'] as String);
      switch (eventType) {
        case sdk.WalletEvent.newTopoHeight:
          final newTopoheight =
              Event.newTopoHeight(json['data']['topoheight'] as int);
          yield newTopoheight;
        case sdk.WalletEvent.newAsset:
          final newAsset = Event.newAsset(
              sdk.AssetWithData.fromJson(json['data'] as Map<String, dynamic>));
          yield newAsset;
        case sdk.WalletEvent.newTransaction:
          final newTransaction = Event.newTransaction(
              sdk.TransactionEntry.fromJson(
                  json['data'] as Map<String, dynamic>));
          yield newTransaction;
        case sdk.WalletEvent.balanceChanged:
          final balanceChanged = Event.balanceChanged(
              sdk.BalanceChangedEvent.fromJson(
                  json['data'] as Map<String, dynamic>));
          yield balanceChanged;
        case sdk.WalletEvent.rescan:
          final rescan = Event.rescan(json['data']['start_topoheight'] as int);
          yield rescan;
        case sdk.WalletEvent.online:
          yield const Event.online();
        case sdk.WalletEvent.offline:
          yield const Event.offline();
      }
    }
  }
}
