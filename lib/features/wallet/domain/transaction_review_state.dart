import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

part 'transaction_review_state.freezed.dart';

@freezed
sealed class TransactionReviewState with _$TransactionReviewState {
  const factory TransactionReviewState.initial({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
  }) = Initial;

  const factory TransactionReviewState.signaturePending({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required wallet_flutter.XelisWalletMultisigSigningRequest request,
    required Object sessionIdentity,
  }) = SignaturePending;

  const factory TransactionReviewState.singleTransferTransaction({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required String asset,
    required String name,
    required String ticker,
    required String amount,
    required String fee,
    required String destination,
    required DestinationAddress destinationAddress,
    required String txHash,
    required wallet_flutter.XelisWalletPreparedTransaction prepared,
    required Object sessionIdentity,
  }) = SingleTransferTransaction;

  const factory TransactionReviewState.burnTransaction({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required String asset,
    required String name,
    required String ticker,
    required String amount,
    required String fee,
    required String txHash,
    required wallet_flutter.XelisWalletPreparedTransaction prepared,
    required Object sessionIdentity,
  }) = BurnTransaction;

  const factory TransactionReviewState.deleteMultisigTransaction({
    @Default(false) bool isBroadcasted,
    @Default(false) bool isConfirmed,
    required String fee,
    required String txHash,
    required wallet_flutter.XelisWalletPreparedTransaction prepared,
    required Object sessionIdentity,
  }) = DeleteMultisigTransaction;
}

extension SingleTransferTransactionMetadata on SingleTransferTransaction {
  wallet_flutter.XelisWalletPreparedTransfer? get preparedTransfer {
    final details = prepared.details;
    if (details is! wallet_flutter.XelisWalletPreparedTransfers ||
        details.transfers.length != 1) {
      return null;
    }

    return details.transfers.single;
  }

  bool get hasAttachedData {
    final transfer = preparedTransfer;
    if (transfer != null) {
      return transfer.hasExtraData;
    }

    return destinationAddress.isIntegrated;
  }

  bool? get attachedDataEncrypted {
    final transfer = preparedTransfer;
    if (transfer == null || !transfer.hasExtraData) {
      return null;
    }

    return transfer.extraDataEncrypted;
  }
}
