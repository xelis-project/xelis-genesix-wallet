import 'dart:async';

import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_mobile_wallet/features/wallet/application/storage_manager.dart';
import 'package:xelis_mobile_wallet/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_mobile_wallet/features/wallet/domain/wallet_snapshot.dart';
import 'package:xelis_mobile_wallet/ffi.dart';
import 'package:xelis_mobile_wallet/shared/logger.dart';
import 'package:xelis_mobile_wallet/shared/utils/cypher.dart';

class WalletService {
  WalletService(
    this.daemonClientRepository,
    this.storageManager,
    this.secretKey,
  );

  final DaemonClientRepository daemonClientRepository;
  final StorageManager storageManager;
  final List<int> secretKey;

  Future<dynamic> sendTransaction(
    String destination,
    String asset,
    int amount,
  ) async {
    final walletSnapshot = await storageManager.getWalletSnapshot();
    if (walletSnapshot != null) {
      final seed = await decrypt(
        secretKey,
        walletSnapshot.encryptedSeed!,
      );
      final balance = await storageManager.getLastBalance(asset);
      final tx = await NativeWalletRepository.createTransaction(
        seed,
        destination,
        balance?.balance ?? 0,
        amount,
        asset,
        walletSnapshot.nonce!,
      );
      final res = await daemonClientRepository.submitTransaction(
        SubmitTransactionParams(hex: tx),
      );
      return res;
    }
  }

  Future<int?> getEstimatedFees(
    String destination,
    String asset,
    int amount,
  ) async {
    final walletSnapshot = await storageManager.getWalletSnapshot();
    if (walletSnapshot != null) {
      final seed = await decrypt(
        secretKey,
        walletSnapshot.encryptedSeed!,
      );
      final fees = await NativeWalletRepository.getEstimatedFees(
        seed,
        destination,
        amount,
        asset,
        walletSnapshot.nonce!,
      );
      return fees;
    }
    return null;
  }

  Future<void> sync() async {
    logger.info('start syncing...');
    try {
      final info = await daemonClientRepository.getInfo();
      logger.info(info);
      await _init(info);
      final walletSnapshot = await storageManager.getWalletSnapshot();
      if (walletSnapshot != null) {
        var walletTopoHeight = walletSnapshot.syncedTopoheight!;

        if (walletTopoHeight < info.topoHeight) {
          await _updateAssets(walletSnapshot.address!);
          await _updateNonce(walletSnapshot.address!);
          // Updating current topoHeight
          await storageManager.setSyncedTopoHeight(info.topoHeight);
        }
      }
    } catch (e) {
      logger.warning('sync: $e');
    }
  }

  Future<String> getSeed() async {
    final walletSnapshot = await storageManager.getWalletSnapshot();
    if (walletSnapshot != null) {
      return decrypt(
        secretKey,
        walletSnapshot.encryptedSeed!,
      );
    }
    return '';
  }

  Future<void> _updateNonce(String address) async {
    int? nonce;
    try {
      nonce = await daemonClientRepository
          .getNonce(GetNonceParams(address: address));
    } catch (e) {
      logger.warning('_updateNonce: $e');
    }
    await storageManager.setNonce(nonce ?? 0);
  }

  // set network version
  Future<void> _setNetworkVersion(Network network) async {
    switch (network) {
      case Network.mainnet:
        await api.setNetworkToMainnet();
        break;
      case Network.testnet:
        await api.setNetworkToTestnet();
        break;
      case Network.dev:
        await api.setNetworkToDev();
        break;
    }
  }

  Future<void> _init(GetInfoResult getInfoResult) async {
    try {
      final walletSnapshot = await storageManager.getWalletSnapshot();
      if (walletSnapshot != null) {
        var needUpdate = false;
        if (walletSnapshot.network == null) {
          needUpdate = true;
          await _setNetworkVersion(getInfoResult.network);
          walletSnapshot.network = getInfoResult.network.name;
        }
        if (walletSnapshot.address == null) {
          needUpdate = true;
          final seed = await getSeed();
          walletSnapshot.address =
              await NativeWalletRepository.getAddress(seed);
        }

        if (walletSnapshot.assets.isEmpty) {
          needUpdate = true;
          await _updateAssets(walletSnapshot.address!);
        }

        if (walletSnapshot.syncedTopoheight == null) {
          needUpdate = true;
          walletSnapshot.syncedTopoheight = getInfoResult.topoHeight;
        }

        if (needUpdate) {
          await storageManager.saveWalletSnapshot(walletSnapshot);
        }
      }
    } catch (e) {
      logger.warning('init: $e');
    }
  }

  Future<void> _updateAssets(String address) async {
    try {
      final getAssetsResult = await daemonClientRepository
          .getAccountAssets(GetAccountAssetsParams(address: address));

      for (final hash in getAssetsResult.assets) {
        final assetEntry = await storageManager.getAsset(hash);

        if (assetEntry != null) {
          // Asset exist in DB
          logger.info("Asset exist in DB : $hash");

          final getLastBalanceResult =
              await daemonClientRepository.getLastBalance(
            GetLastBalanceParams(address: address, asset: hash),
          );

          if (getLastBalanceResult.topoHeight >
              assetEntry.lastBalanceTopoheight!) {
            var previousTopoheight =
                getLastBalanceResult.balance.previousTopoHeight;

            await _updateAsset(
              address,
              hash,
              getLastBalanceResult.balance.balance,
              getLastBalanceResult.topoHeight,
              previousTopoheight == null ? true : false,
            );

            _updateAssetHistory(address, getLastBalanceResult.topoHeight);

            while (previousTopoheight! > assetEntry.lastBalanceTopoheight!) {
              final getBalanceResult =
                  await daemonClientRepository.getBalanceAtTopoHeight(
                GetBalanceAtTopoHeightParams(
                  address: address,
                  asset: hash,
                  topoHeight: previousTopoheight,
                ),
              );

              await _updateAsset(
                address,
                hash,
                getBalanceResult.balance,
                previousTopoheight,
                getBalanceResult.previousTopoHeight == null ? true : false,
              );

              _updateAssetHistory(address, previousTopoheight);

              previousTopoheight = getBalanceResult.previousTopoHeight;
            }
          }
        } else {
          // Asset doesn't exist in DB
          logger.info("Asset doesn't exist in DB : $hash");

          final getLastBalanceResult =
              await daemonClientRepository.getLastBalance(
            GetLastBalanceParams(address: address, asset: hash),
          );

          var previousTopoheight =
              getLastBalanceResult.balance.previousTopoHeight;

          await _updateAsset(
            address,
            hash,
            getLastBalanceResult.balance.balance,
            getLastBalanceResult.topoHeight,
            previousTopoheight == null ? true : false,
          );

          _updateAssetHistory(address, getLastBalanceResult.topoHeight);

          while (previousTopoheight != null) {
            final getBalanceResult =
                await daemonClientRepository.getBalanceAtTopoHeight(
              GetBalanceAtTopoHeightParams(
                address: address,
                asset: hash,
                topoHeight: previousTopoheight,
              ),
            );

            await _updateAsset(
              address,
              hash,
              getBalanceResult.balance,
              previousTopoheight,
              getBalanceResult.previousTopoHeight == null ? true : false,
            );

            _updateAssetHistory(address, previousTopoheight);

            previousTopoheight = getBalanceResult.previousTopoHeight;
          }
        }
      }
    } catch (e) {
      logger.warning('updateAssets: $e');
    }
  }

  Future<void> _updateAsset(
    String address,
    String assetHash,
    int balance,
    int topoHeight,
    bool synced,
  ) async {
    try {
      logger.info(
          'updateAsset: Asset($assetHash) - Topoheight($topoHeight) - Balance($balance)');

      await storageManager.addVersionedBalance(
        assetHash,
        balance,
        topoHeight,
        synced,
      );
    } catch (e) {
      logger.warning('updateAsset: $e');
    }
  }

  Future<void> _updateAssetHistory(String address, int topoHeight) async {
    try {
      final block = await daemonClientRepository.getBlockAtTopoHeight(
        GetBlockAtTopoHeightParams(topoHeight: topoHeight, includeTxs: true),
      );

      if (block.miner == address) {
        final coinbase = EntryData()..coinbase = block.reward;
        final txEntry = TransactionEntry()
          ..hash = block.hash
          ..topoHeight = block.topoHeight
          ..entryData = coinbase;
        await storageManager.addTransaction(txEntry);
      }

      if (block.txsHashes.isNotEmpty) {
        for (final txHash in block.txsHashes) {
          final tx = await daemonClientRepository.getTransaction(
            GetTransactionParams(hash: txHash),
          );
          final isOwner = tx.owner == address;

          final txEntry = TransactionEntry()
            ..hash = tx.hash
            ..topoHeight = block.topoHeight
            ..fees = isOwner ? tx.fee : null
            ..nonce = isOwner ? tx.nonce : null
            ..executedInBlock = tx.executedInBlock
            ..owner = tx.owner
            ..signature = tx.signature;

          final entryData = EntryData();

          if (tx.data.burn != null && isOwner) {
            final burn = BurnEntry()
              ..asset = tx.data.burn!.asset
              ..amount = tx.data.burn!.amount;
            entryData.burn = burn;
          }

          if (tx.data.transfers != null) {
            final transfers = <TransferEntry>[];
            for (final transfer in tx.data.transfers!) {
              final isTransferOwner = transfer.to == address;
              if (isTransferOwner || isOwner) {
                final transferEntry = TransferEntry()
                  ..asset = transfer.asset
                  ..amount = transfer.amount
                  ..to = transfer.to
                  ..extraData = transfer.extraData.toString();
                transfers.add(transferEntry);
              }
            }

            if (isOwner) {
              final outgoingEntry = OutgoingEntry()..transfers = transfers;
              entryData.outgoing = outgoingEntry;
            } else if (transfers.isNotEmpty) {
              final incomingEntry = IncomingEntry()
                ..owner = tx.owner
                ..transfers = transfers;
              entryData.incoming = incomingEntry;
            }
          }

          final isExecuted = await daemonClientRepository.isTxExecutedInBlock(
              IsTxExecutedInBlockParams(txHash: txHash, blockHash: block.hash));

          if (entryData.hasData() && isExecuted) {
            txEntry.entryData = entryData;
            await storageManager.addTransaction(txEntry);
          }
        }
      }
    } catch (e) {
      logger.warning('updateHistory: $e');
      rethrow;
    }
  }
}
