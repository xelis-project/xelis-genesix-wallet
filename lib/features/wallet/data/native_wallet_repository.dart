import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:genesix/features/wallet/domain/multisig/multisig_state.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/address_book_dtos.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/wallet_dtos.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/xswd_dtos.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';
import 'package:genesix/src/generated/rust_bridge/api/precomputed_tables.dart'
    as tables_api;
import 'package:genesix/src/generated/rust_bridge/api/precomputed_tables.dart'
    show arePrecomputedTablesAvailable;

import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as sdk;
import 'package:genesix/features/wallet/domain/event.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/src/generated/rust_bridge/api/wallet.dart';

class NativeWalletRepository {
  NativeWalletRepository._internal(this._xelisWallet);

  final XelisWallet _xelisWallet;

  // Only one background upgrade at a time
  static Completer<void>? _tableUpgradeCompleter;

  static Future<NativeWalletRepository> create(
    String walletPath,
    String pwd,
    Network network, {
    String? precomputeTablesPath,
    required tables_api.PrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet = await createXelisWallet(
      directory: walletPath,
      name: "",
      password: pwd,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
      precomputedTableType: precomputedTableType,
    );

    unawaited(
      _maybeUpgradeTablesInBackground(
        precomputeTablesPath: precomputeTablesPath,
        desiredType: precomputedTableType,
      ),
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
    required tables_api.PrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet = await createXelisWallet(
      directory: walletPath,
      name: "",
      password: pwd,
      seed: seed,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
      precomputedTableType: precomputedTableType,
    );

    unawaited(
      _maybeUpgradeTablesInBackground(
        precomputeTablesPath: precomputeTablesPath,
        desiredType: precomputedTableType,
      ),
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
    required tables_api.PrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet = await createXelisWallet(
      directory: walletPath,
      name: "",
      password: pwd,
      privateKey: privateKey,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
      precomputedTableType: precomputedTableType,
    );

    unawaited(
      _maybeUpgradeTablesInBackground(
        precomputeTablesPath: precomputeTablesPath,
        desiredType: precomputedTableType,
      ),
    );

    talker.info('XELIS Wallet recovered from private key: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<NativeWalletRepository> open(
    String walletPath,
    String pwd,
    Network network, {
    String? precomputeTablesPath,
    required tables_api.PrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet = await openXelisWallet(
      directory: walletPath,
      name: "",
      password: pwd,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
      precomputedTableType: precomputedTableType,
    );

    unawaited(
      _maybeUpgradeTablesInBackground(
        precomputeTablesPath: precomputeTablesPath,
        desiredType: precomputedTableType,
      ),
    );

    talker.info('XELIS Wallet open: $walletPath');
    return NativeWalletRepository._internal(xelisWallet);
  }

  static Future<void> _maybeUpgradeTablesInBackground({
    required String? precomputeTablesPath,
    required tables_api.PrecomputedTableType desiredType,
  }) async {
    if (precomputeTablesPath == null) return;
    if (kIsWeb) return;

    // If an upgrade is already running, just wait for it once.
    if (_tableUpgradeCompleter != null) {
      try {
        await _tableUpgradeCompleter!.future;
      } catch (_) {
        // Previous attempt failed; allow caller to trigger another one later.
      }
      return;
    }

    final completer = Completer<void>();
    _tableUpgradeCompleter = completer;

    try {
      final tablesExist = await arePrecomputedTablesAvailable(
        precomputedTablesPath: precomputeTablesPath,
        precomputedTableType: desiredType,
      );

      if (tablesExist) {
        completer.complete();
        return;
      }

      talker.info('XELIS: upgrading precomputed tables to $desiredType');

      await updateTables(
        precomputedTablesPath: precomputeTablesPath,
        precomputedTableType: desiredType,
      );

      talker.info('XELIS: precomputed table upgrade complete');
      completer.complete();
    } catch (e, s) {
      talker.error('XELIS: precomputed table upgrade failed', e, s);
      completer.completeError(e);
      // don't rethrow: this is best-effort background work
    } finally {
      _tableUpgradeCompleter = null;
    }
  }

  Future<void> updatePrecomputedTables(
    String precomputeTablesPath,
    tables_api.PrecomputedTableType precomputedTableType,
  ) async {
    talker.info('Updating precomputed tables to type: $precomputedTableType');
    await updateTables(
      precomputedTablesPath: precomputeTablesPath,
      precomputedTableType: precomputedTableType,
    );
  }

  Future<void> close() async {
    await _xelisWallet.close();
  }

  void dispose() {
    dropWallet(wallet: _xelisWallet);
    _xelisWallet.dispose();
    if (_xelisWallet.isDisposed) talker.info('Rust Wallet disposed');
  }

  XelisWallet get nativeWallet => _xelisWallet;

  String get address => _xelisWallet.getAddressStr();

  Future<BigInt> get nonce => _xelisWallet.getNonce();

  Future<bool> get isOnline => _xelisWallet.isOnline();

  Network get network => _xelisWallet.getNetwork();

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
              sdk.RPCAssetData.fromJson(json['data'] as Map<String, dynamic>),
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
          case sdk.WalletEvent.syncError:
            final syncError = Event.syncError(
              json['data']['message'] as String,
            );
            yield syncError;
          case sdk.WalletEvent.trackAsset:
            final trackAsset = Event.trackAsset(
              json['data']['asset'] as String,
            );
            yield trackAsset;
          case sdk.WalletEvent.untrackAsset:
            final untrackAsset = Event.untrackAsset(
              json['data']['asset'] as String,
            );
            yield untrackAsset;
        }
      } catch (e) {
        talker.error('Unknown event: ${json['event']}: $json');
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

  Future<bool> hasAssetBalance(String assetHash) async {
    return _xelisWallet.hasAssetBalance(asset: assetHash);
  }

  Future<Map<String, String>> getTrackedBalances() async {
    return _xelisWallet.getTrackedBalances();
  }

  Future<Map<String, sdk.AssetData>> getKnownAssets() async {
    final rawData = await _xelisWallet.getKnownAssets();
    final result = <String, sdk.AssetData>{};

    for (final entry in rawData.entries) {
      try {
        final json = jsonDecode(entry.value) as Map<String, dynamic>;
        final assetData = sdk.AssetData.fromJson(json);
        result[entry.key] = assetData;
      } catch (e, stack) {
        talker.error(
          'Failed to parse asset ${entry.key}: $e\n${entry.value}',
          e,
          stack,
        );
      }
    }

    return result;
  }

  Future<bool> trackAsset(String assetHash) async {
    final result = await _xelisWallet.trackAsset(asset: assetHash);
    return result;
  }

  Future<bool> untrackAsset(String assetHash) async {
    final result = await _xelisWallet.untrackAsset(asset: assetHash);
    return result;
  }

  Future<sdk.AssetData> getAssetMetadata(String assetHash) async {
    final jsonStr = await _xelisWallet.getAssetMetadata(asset: assetHash);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return sdk.AssetData.fromJson(json);
  }

  Future<List<Map<String, dynamic>>> getContractLogs(String txHash) async {
    final jsonStr = await _xelisWallet.getContractLogs(txHash: txHash);
    final json = jsonDecode(jsonStr) as List;
    return json.cast<Map<String, dynamic>>();
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
    final List<sdk.TransactionEntry> entries = [];

    for (final rawEntry in rawData) {
      try {
        final decoded = jsonDecode(rawEntry) as Map<String, dynamic>;

        // Backwards compatibility: rename chunk_id to entry_id for old transactions
        if (decoded.containsKey('invoke_contract')) {
          final invokeContract =
              decoded['invoke_contract'] as Map<String, dynamic>;
          if (invokeContract.containsKey('chunk_id') &&
              !invokeContract.containsKey('entry_id')) {
            invokeContract['entry_id'] = invokeContract['chunk_id'];
          }
        }

        final entry = sdk.TransactionEntry.fromJson(decoded);
        entries.add(entry);
      } catch (e) {
        talker.error('Failed to parse transaction: $e');
        talker.error('Raw JSON: $rawEntry');
        // Skip this transaction instead of crashing
        continue;
      }
    }

    return entries;
  }

  Future<sdk.GetInfoResult> getDaemonInfo() async {
    final rawData = await _xelisWallet.getDaemonInfo();
    final json = jsonDecode(rawData);
    return sdk.GetInfoResult.fromJson(json as Map<String, dynamic>);
  }

  Future<void> rescan({required int topoheight}) async {
    return _xelisWallet.rescan(topoheight: BigInt.from(topoheight));
  }

  Future<String> estimateFees(List<Transfer> transfers) async {
    return _xelisWallet.estimateFees(transfers: transfers);
  }

  Future<TransactionSummary> createTransferTransaction({
    double? amount,
    required String address,
    required String assetHash,
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
      );
    } else {
      rawTx = await _xelisWallet.createTransferAllTransaction(
        strAddress: address,
        assetHash: assetHash,
      );
    }
    final jsonTx = jsonDecode(rawTx) as Map<String, dynamic>;
    return TransactionSummary.fromJson(jsonTx);
  }

  Future<String> createMultisigTransferTransaction({
    double? amount,
    required String address,
    required String assetHash,
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
      );
    } else {
      return _xelisWallet.createMultisigTransferAllTransaction(
        strAddress: address,
        assetHash: assetHash,
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

  Future<void> startXSWD({
    required Future<void> Function(XswdRequestSummary) cancelRequestCallback,
    required Future<UserPermissionDecision> Function(XswdRequestSummary)
    requestApplicationCallback,
    required Future<UserPermissionDecision> Function(XswdRequestSummary)
    requestPermissionCallback,
    required Future<UserPermissionDecision> Function(XswdRequestSummary)
    requestPrefetchPermissionsCallback,
    required Future<void> Function(XswdRequestSummary) appDisconnectCallback,
  }) async {
    if (await _xelisWallet.isXswdRunning()) {
      talker.warning('XSWD already running...');
      return;
    }
    await _xelisWallet.startXswd(
      cancelRequestDartCallback: cancelRequestCallback,
      requestApplicationDartCallback: requestApplicationCallback,
      requestPermissionDartCallback: requestPermissionCallback,
      requestPrefetchPermissionsDartCallback:
          requestPrefetchPermissionsCallback,
      appDisconnectDartCallback: appDisconnectCallback,
    );
  }

  Future<void> stopXSWD() async {
    if (!await _xelisWallet.isXswdRunning()) {
      talker.warning('XSWD already stopped...');
      return;
    }
    await _xelisWallet.stopXswd();
  }

  Future<bool> isXswdRunning() async {
    return await _xelisWallet.isXswdRunning();
  }

  Future<List<AppInfo>> getXswdState() async {
    if (!await _xelisWallet.isXswdRunning()) {
      talker.info('XSWD state not available, XSWD is not running');
      return [];
    }
    return _xelisWallet.getApplicationPermissions();
  }

  Future<void> removeXswdApp(String appID) async {
    await _xelisWallet.closeApplicationSession(id: appID);
  }

  Future<void> addXswdRelayer(
    {
      required Future<void> Function(XswdRequestSummary) cancelRequestCallback,
      required Future<UserPermissionDecision> Function(XswdRequestSummary)
      requestApplicationCallback,
      required Future<UserPermissionDecision> Function(XswdRequestSummary)
      requestPermissionCallback,
      required Future<UserPermissionDecision> Function(XswdRequestSummary)
      requestPrefetchPermissionsCallback,
      required Future<void> Function(XswdRequestSummary) appDisconnectCallback,
      required ApplicationDataRelayer relayerData,
    }
  ) async {
    await _xelisWallet.addXswdRelayer(
      appData: relayerData,
      cancelRequestDartCallback: cancelRequestCallback,
      requestApplicationDartCallback: requestApplicationCallback,
      requestPermissionDartCallback: requestPermissionCallback,
      requestPrefetchPermissionsDartCallback:
          requestPrefetchPermissionsCallback,
      appDisconnectDartCallback: appDisconnectCallback,      
    );
  }

  Future<void> modifyXSWDAppPermissions(
    String appID,
    Map<String, PermissionPolicy> permissions,
  ) async {
    await _xelisWallet.modifyApplicationPermissions(
      id: appID,
      permissions: permissions,
    );
  }

  Future<AddressBookData> retrieveContacts({int? skip, int? take}) async {
    return _xelisWallet.retrieveContacts(
      skip: skip != null ? BigInt.from(skip) : null,
      take: take != null ? BigInt.from(take) : null,
    );
  }

  Future<int> countContacts() async {
    final count = await _xelisWallet.countContacts();
    return count.toInt();
  }

  Future<void> upsertContact({
    required String name,
    required String address,
    String? note,
  }) async {
    await _xelisWallet.upsertContact(
      entry: ContactDetails(name: name, address: address, note: note),
    );
  }

  Future<void> removeContact(String address) async {
    await _xelisWallet.removeContact(address: address);
  }

  Future<bool> isContactPresent(String address) async {
    final isPresent = await _xelisWallet.isContactPresent(address: address);
    return isPresent;
  }

  Future<ContactDetails> getContact(String address) async {
    final contact = await _xelisWallet.findContactByAddress(address: address);
    return contact;
  }

  Future<AddressBookData> findContactsByName(
    String name, {
    int? skip,
    int? take,
  }) async {
    final contacts = await _xelisWallet.findContactsByName(
      name: name,
      skip: skip != null ? BigInt.from(skip) : null,
      take: take != null ? BigInt.from(take) : null,
    );
    return contacts;
  }

  Future<void> exportTransactionsToCsvFile(String path) async {
    await _xelisWallet.exportTransactionsToCsvFile(filePath: path);
  }

  Future<String> convertTransactionsToCsv() async {
    return _xelisWallet.convertTransactionsToCsv();
  }
}
