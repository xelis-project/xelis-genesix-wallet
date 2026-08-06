import 'dart:async';

import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

import 'package:genesix/features/logger/logger.dart';

class NativeWalletRepository {
  NativeWalletRepository._internal(this._wallet, this._network);

  final wallet_flutter.XelisWallet _wallet;
  final wallet_flutter.XelisNetwork _network;

  static Future<NativeWalletRepository> create(
    String walletPath,
    String pwd,
    wallet_flutter.XelisNetwork network, {
    String? precomputeTablesPath,
    required wallet_flutter.XelisPrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet = await wallet_flutter.XelisWalletFlutter.createWallet(
      walletPath: walletPath,
      password: pwd,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
      precomputedTableType: precomputedTableType,
    );

    logDiagnostic(() => 'New XELIS wallet created: path=$walletPath');
    return NativeWalletRepository._internal(xelisWallet, network);
  }

  static Future<NativeWalletRepository> recoverFromSeed(
    String walletPath,
    String pwd,
    wallet_flutter.XelisNetwork network, {
    required String seed,
    String? precomputeTablesPath,
    required wallet_flutter.XelisPrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet =
        await wallet_flutter.XelisWalletFlutter.recoverWalletFromSeed(
          walletPath: walletPath,
          password: pwd,
          seed: seed,
          network: network,
          precomputedTablesPath: precomputeTablesPath,
          precomputedTableType: precomputedTableType,
        );

    logDiagnostic(() => 'XELIS wallet recovered from seed: path=$walletPath');
    return NativeWalletRepository._internal(xelisWallet, network);
  }

  static Future<NativeWalletRepository> recoverFromPrivateKey(
    String walletPath,
    String pwd,
    wallet_flutter.XelisNetwork network, {
    required String privateKey,
    String? precomputeTablesPath,
    required wallet_flutter.XelisPrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet =
        await wallet_flutter.XelisWalletFlutter.recoverWalletFromPrivateKey(
          walletPath: walletPath,
          password: pwd,
          privateKey: privateKey,
          network: network,
          precomputedTablesPath: precomputeTablesPath,
          precomputedTableType: precomputedTableType,
        );

    logDiagnostic(
      () => 'XELIS wallet recovered from private key: path=$walletPath',
    );
    return NativeWalletRepository._internal(xelisWallet, network);
  }

  static Future<NativeWalletRepository> open(
    String walletPath,
    String pwd,
    wallet_flutter.XelisNetwork network, {
    String? precomputeTablesPath,
    required wallet_flutter.XelisPrecomputedTableType precomputedTableType,
  }) async {
    final xelisWallet = await wallet_flutter.XelisWalletFlutter.openWallet(
      walletPath: walletPath,
      password: pwd,
      network: network,
      precomputedTablesPath: precomputeTablesPath,
      precomputedTableType: precomputedTableType,
    );

    logDiagnostic(() => 'XELIS wallet opened: path=$walletPath');
    return NativeWalletRepository._internal(xelisWallet, network);
  }

  Future<void> close() async {
    talker.info('Closing native XELIS wallet');
    await _wallet.close();
    talker.info('Native XELIS wallet closed');
  }

  void dispose() {
    _wallet.dispose();
    if (_wallet.isDisposed) talker.info('Native XELIS wallet disposed');
  }

  String get address => _wallet.address;

  Future<bool> get isOnline => _wallet.isOnline();

  Future<bool> get isSyncing => _wallet.isSyncing();

  wallet_flutter.XelisNetwork get network => _network;

  Future<void> setOnline({required String daemonAddress}) async {
    await _wallet.setOnline(daemonAddress: daemonAddress);
    logDiagnostic(
      () =>
          'XELIS wallet connected: '
          'endpoint=${sanitizeEndpointForDiagnostics(daemonAddress)}',
    );
  }

  Future<void> setOffline() async {
    await _wallet.setOffline();
    talker.info('XELIS Wallet offline');
  }

  Future<wallet_flutter.XelisWalletRuntimeEventSubscription>
  subscribeRuntimeEvents() => _wallet.subscribeRuntimeEvents();

  Future<wallet_flutter.XelisWalletBusinessEventSubscription>
  subscribeBusinessEvents() => _wallet.subscribeBusinessEvents();

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return _wallet.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<String> getSeed({
    wallet_flutter.SeedLanguage language = wallet_flutter.SeedLanguage.english,
  }) async {
    return _wallet.getSeed(language: language);
  }

  Future<void> isValidPassword(String password) async {
    return _wallet.verifyPassword(password: password);
  }

  Future<BigInt> getXelisBalance() async {
    return _wallet.getXelisBalance();
  }

  Future<Map<String, BigInt>> getTrackedBalances() async {
    return _wallet.getTrackedBalances();
  }

  Future<Map<String, wallet_flutter.XelisWalletAssetMetadata>>
  getKnownAssets() async {
    return _wallet.getKnownAssets();
  }

  Future<bool> trackAsset(String assetHash) async {
    return _wallet.trackAsset(asset: assetHash);
  }

  Future<bool> untrackAsset(String assetHash) async {
    return _wallet.untrackAsset(asset: assetHash);
  }

  Future<wallet_flutter.XelisWalletAssetMetadata> getAssetMetadata(
    String assetHash,
  ) async {
    return _wallet.getAssetMetadata(asset: assetHash);
  }

  Future<BigInt> getHistoryCount() => _wallet.getHistoryCount();

  Future<List<wallet_flutter.XelisWalletTransactionEntry>> history({
    required wallet_flutter.XelisWalletHistoryFilter filter,
    wallet_flutter.XelisWalletExtraDataDisclosure extraDataDisclosure =
        wallet_flutter.XelisWalletExtraDataDisclosure.metadata,
  }) =>
      _wallet.history(filter: filter, extraDataDisclosure: extraDataDisclosure);

  Future<List<wallet_flutter.XelisWalletPendingTransaction>>
  pendingTransactions({
    wallet_flutter.XelisWalletExtraDataDisclosure extraDataDisclosure =
        wallet_flutter.XelisWalletExtraDataDisclosure.metadata,
  }) => _wallet.pendingTransactions(extraDataDisclosure: extraDataDisclosure);

  Future<wallet_flutter.XelisWalletTransactionEntry> transactionByHash({
    required String hash,
    wallet_flutter.XelisWalletExtraDataDisclosure extraDataDisclosure =
        wallet_flutter.XelisWalletExtraDataDisclosure.metadata,
  }) => _wallet.transactionByHash(
    hash: hash,
    extraDataDisclosure: extraDataDisclosure,
  );

  Future<wallet_flutter.XelisWalletPendingTransaction>
  pendingTransactionByHash({
    required String hash,
    wallet_flutter.XelisWalletExtraDataDisclosure extraDataDisclosure =
        wallet_flutter.XelisWalletExtraDataDisclosure.metadata,
  }) => _wallet.pendingTransactionByHash(
    hash: hash,
    extraDataDisclosure: extraDataDisclosure,
  );

  Future<wallet_flutter.XelisDaemonInfo> getDaemonInfo() =>
      _wallet.getDaemonInfo();

  Future<void> rescan({required BigInt topoheight}) async {
    return _wallet.rescan(topoheight: topoheight);
  }

  Future<BigInt> estimateTransferFees(
    List<wallet_flutter.XelisWalletTransferRequest> transfers, {
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) {
    return _wallet.estimateTransferFees(
      transfers: transfers,
      feePolicy: feePolicy,
    );
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction>
  prepareTransferTransaction({
    required BigInt amountAtomic,
    required String address,
    required String assetHash,
    String? extraData,
    bool encryptExtraData = true,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) {
    return _wallet.prepareTransfers(
      transfers: [
        wallet_flutter.XelisWalletTransferRequest(
          destination: address,
          asset: assetHash,
          amountAtomic: amountAtomic,
          extraData: extraData,
          encryptExtraData: encryptExtraData,
        ),
      ],
      feePolicy: feePolicy,
    );
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction> prepareTransferAll({
    required String address,
    required String assetHash,
    String? extraData,
    bool encryptExtraData = true,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) {
    return _wallet.prepareTransferAll(
      destination: address,
      asset: assetHash,
      extraData: extraData,
      encryptExtraData: encryptExtraData,
      feePolicy: feePolicy,
    );
  }

  Future<wallet_flutter.XelisWalletPreparedTransferExtraData>
  inspectPreparedTransferExtraData(
    wallet_flutter.XelisWalletPreparedTransaction transaction, {
    int transferIndex = 0,
  }) {
    return _wallet.inspectPreparedTransferExtraData(
      transaction: transaction,
      transferIndex: transferIndex,
    );
  }

  Future<wallet_flutter.XelisWalletMultisigSigningRequest>
  createMultisigTransferTransaction({
    BigInt? amountAtomic,
    required String address,
    required String assetHash,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    if (amountAtomic != null) {
      return _wallet.prepareMultisigTransfers(
        transfers: [
          wallet_flutter.XelisWalletTransferRequest(
            amountAtomic: amountAtomic,
            destination: address,
            asset: assetHash,
          ),
        ],
        feePolicy: feePolicy,
      );
    } else {
      return _wallet.prepareMultisigTransferAll(
        destination: address,
        asset: assetHash,
        feePolicy: feePolicy,
      );
    }
  }

  Future<wallet_flutter.XelisWalletMultisigSigningRequest>
  createMultisigTransfersTransaction(
    List<wallet_flutter.XelisWalletTransferRequest> transfers, {
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    return _wallet.prepareMultisigTransfers(
      transfers: transfers,
      feePolicy: feePolicy,
    );
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction> prepareBurnTransaction({
    required BigInt amountAtomic,
    required String assetHash,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) {
    return _wallet.prepareBurn(
      asset: assetHash,
      amountAtomic: amountAtomic,
      feePolicy: feePolicy,
    );
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction> prepareBurnAll({
    required String assetHash,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) {
    return _wallet.prepareBurnAll(asset: assetHash, feePolicy: feePolicy);
  }

  Future<wallet_flutter.XelisWalletMultisigSigningRequest>
  createMultisigBurnTransaction({
    BigInt? amountAtomic,
    required String assetHash,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) async {
    if (amountAtomic == null) {
      return _wallet.prepareMultisigBurnAll(
        asset: assetHash,
        feePolicy: feePolicy,
      );
    } else {
      return _wallet.prepareMultisigBurn(
        amountAtomic: amountAtomic,
        asset: assetHash,
        feePolicy: feePolicy,
      );
    }
  }

  Future<wallet_flutter.XelisWalletBroadcastResult>
  broadcastPreparedTransaction(
    wallet_flutter.XelisWalletPreparedTransaction transaction,
  ) async {
    final outcome = await _wallet.broadcastPreparedTransaction(
      transaction: transaction,
    );
    talker.info(
      'Prepared transaction broadcast completed: '
      'outcome=${outcome.runtimeType}',
    );
    return outcome;
  }

  Future<void> discardPreparedTransaction(
    wallet_flutter.XelisWalletPreparedTransaction transaction,
  ) async {
    await _wallet.discardPreparedTransaction(transaction: transaction);
    logDiagnostic(
      () => 'Prepared transaction canceled: hash=${transaction.hash}',
    );
  }

  Future<wallet_flutter.XelisWalletMultisigState?> getMultisigState() {
    return _wallet.getMultisigState();
  }

  Future<wallet_flutter.XelisWalletMultisigSigningRequest>
  inspectMultisigSigningRequest(String encoded) {
    return _wallet.inspectMultisigSigningRequest(encoded: encoded);
  }

  Future<wallet_flutter.XelisWalletMultisigSignatureShare>
  signMultisigSigningRequest(
    wallet_flutter.XelisWalletMultisigSigningRequest request,
  ) {
    return _wallet.signMultisigSigningRequest(request: request);
  }

  Future<wallet_flutter.XelisWalletMultisigSignatureShare>
  inspectMultisigSignatureShare({
    required wallet_flutter.XelisWalletMultisigSigningRequest request,
    required String encoded,
  }) {
    return _wallet.inspectMultisigSignatureShare(
      request: request,
      encoded: encoded,
    );
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction> setupMultisig({
    required List<String> participants,
    required int threshold,
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) {
    return _wallet.prepareMultisigSetup(
      threshold: threshold,
      participants: participants,
      feePolicy: feePolicy,
    );
  }

  bool isAddressValidForMultisig(String address) {
    return _wallet.isMultisigParticipantAddressValid(address: address);
  }

  Future<wallet_flutter.XelisWalletMultisigSigningRequest> initDeleteMultisig({
    wallet_flutter.XelisWalletFeePolicy feePolicy =
        wallet_flutter.XelisWalletFeePolicy.automatic,
  }) {
    return _wallet.prepareMultisigDeletion(feePolicy: feePolicy);
  }

  Future<wallet_flutter.XelisWalletPreparedTransaction>
  finalizeMultisigTransaction({
    required wallet_flutter.XelisWalletMultisigSigningRequest request,
    required List<wallet_flutter.XelisWalletMultisigSignatureShare> shares,
  }) {
    return _wallet.finalizeMultisigTransaction(
      request: request,
      shares: shares,
    );
  }

  Future<void> cancelPendingMultisigRequest(
    wallet_flutter.XelisWalletMultisigSigningRequest request,
  ) {
    return _wallet.cancelMultisigSigningRequest(request: request);
  }

  Future<void> startXSWD({
    required wallet_flutter.XelisXswdCallbacks callbacks,
  }) async {
    await _wallet.startXswd(callbacks: callbacks);
  }

  Future<void> stopXSWD() => _wallet.stopXswd();

  Future<wallet_flutter.XelisXswdState> getXswdState() =>
      _wallet.getXswdState();

  Future<void> removeXswdApp(String appID) =>
      _wallet.closeXswdApplicationSession(applicationId: appID);

  Future<void> addXswdRelayer({
    required wallet_flutter.XelisXswdCallbacks callbacks,
    required wallet_flutter.XelisXswdRelayer relayerData,
  }) async {
    await _wallet.addXswdRelayer(relayer: relayerData, callbacks: callbacks);
  }

  Future<void> modifyXSWDAppPermissions(
    String appID,
    Map<String, wallet_flutter.XelisXswdPermissionPolicy> permissions,
  ) async {
    await _wallet.updateXswdApplicationPermissions(
      applicationId: appID,
      permissions: permissions,
    );
  }

  Future<wallet_flutter.XelisAddressBookPage> addressBookEntries({
    String? query,
    int skip = 0,
    int? take,
  }) {
    return _wallet.addressBookEntries(query: query, skip: skip, take: take);
  }

  Future<wallet_flutter.XelisAddressBookEntry> upsertAddressBookEntry({
    required String address,
    required String displayName,
    String? destinationLabel,
    String? note,
  }) {
    return _wallet.upsertAddressBookEntry(
      address: address,
      displayName: displayName,
      destinationLabel: destinationLabel,
      note: note,
    );
  }

  Future<void> removeAddressBookEntry(String entryId) {
    return _wallet.removeAddressBookEntry(entryId: entryId);
  }

  Future<wallet_flutter.XelisAddressBookEntry> addressBookEntry(
    String entryId,
  ) {
    return _wallet.addressBookEntry(entryId: entryId);
  }

  Future<wallet_flutter.XelisAddressBookMatch> matchAddressBookAddress(
    String address,
  ) {
    return _wallet.matchAddressBookAddress(address: address);
  }

  Future<wallet_flutter.XelisAddressBookMatch> matchAddressBookDestination({
    required String baseAddress,
    wallet_flutter.XelisDataElement? integratedData,
  }) {
    return _wallet.matchAddressBookDestination(
      baseAddress: baseAddress,
      integratedData: integratedData,
    );
  }

  Future<void> exportTransactionsToCsvFile(
    String path,
    wallet_flutter.XelisWalletHistoryFilter filter,
  ) async {
    await _wallet.exportTransactionsToCsvFile(filePath: path, filter: filter);
  }

  Future<String> convertTransactionsToCsv(
    wallet_flutter.XelisWalletHistoryFilter filter,
  ) async {
    return _wallet.convertTransactionsToCsv(filter: filter);
  }
}
