import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/shared/providers/provider_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart'
    as wallet_flutter;

part 'transaction_review_provider.g.dart';

@riverpod
class TransactionReview extends _$TransactionReview {
  @override
  TransactionReviewState build() {
    ref.watch(activeWalletSessionProvider);
    ref.cacheFor(Duration(seconds: 3));
    return TransactionReviewState.initial();
  }

  void signaturePending(
    wallet_flutter.XelisWalletMultisigSigningRequest request, {
    required Object sessionIdentity,
  }) {
    _requireActiveSession(sessionIdentity);
    state = TransactionReviewState.signaturePending(
      request: request,
      sessionIdentity: sessionIdentity,
    );
  }

  void setPreparedSingleTransferTransaction(
    wallet_flutter.XelisWalletPreparedTransaction prepared, {
    required Object sessionIdentity,
  }) {
    _requireActiveSession(sessionIdentity);
    final details = prepared.details;
    if (details is! wallet_flutter.XelisWalletPreparedTransfers ||
        details.transfers.length != 1) {
      throw ArgumentError.value(
        prepared,
        'prepared',
        'Expected exactly one prepared transfer.',
      );
    }

    final transfer = details.transfers.single;
    _setSingleTransferTransaction(
      asset: transfer.asset,
      destination: transfer.destination,
      amountAtomic: transfer.amountAtomic,
      feeAtomic: prepared.feeAtomic,
      txHash: prepared.hash,
      prepared: prepared,
      sessionIdentity: sessionIdentity,
    );
  }

  void _setSingleTransferTransaction({
    required String asset,
    required String destination,
    required BigInt amountAtomic,
    required BigInt feeAtomic,
    required String txHash,
    required wallet_flutter.XelisWalletPreparedTransaction prepared,
    required Object sessionIdentity,
  }) {
    final network = ref.read(
      walletRuntimeProvider.select((state) => state.network),
    );
    final knownAssets = ref.read(
      walletRuntimeProvider.select((state) => state.knownAssets),
    );
    final name = knownAssets[asset]?.name ?? '';
    final ticker = knownAssets[asset]?.ticker ?? '';
    final decimals = knownAssets[asset]?.decimals ?? 0;
    final formattedAmount = formatCoin(amountAtomic, decimals, ticker);

    state = TransactionReviewState.singleTransferTransaction(
      asset: asset,
      name: name,
      ticker: ticker,
      amount: formattedAmount,
      fee: formatXelis(feeAtomic, network),
      destination: destination,
      destinationAddress: parseRawAddress(rawAddress: destination),
      txHash: txHash,
      prepared: prepared,
      sessionIdentity: sessionIdentity,
    );
  }

  void setPreparedBurnTransaction(
    wallet_flutter.XelisWalletPreparedTransaction prepared, {
    required Object sessionIdentity,
  }) {
    _requireActiveSession(sessionIdentity);
    final details = prepared.details;
    if (details is! wallet_flutter.XelisWalletPreparedBurn) {
      throw ArgumentError.value(
        prepared,
        'prepared',
        'Expected prepared burn details.',
      );
    }

    _setBurnTransaction(
      asset: details.asset,
      amountAtomic: details.amountAtomic,
      feeAtomic: prepared.feeAtomic,
      txHash: prepared.hash,
      prepared: prepared,
      sessionIdentity: sessionIdentity,
    );
  }

  void _setBurnTransaction({
    required String asset,
    required BigInt amountAtomic,
    required BigInt feeAtomic,
    required String txHash,
    required wallet_flutter.XelisWalletPreparedTransaction prepared,
    required Object sessionIdentity,
  }) {
    final network = ref.read(
      walletRuntimeProvider.select((state) => state.network),
    );
    final knownAssets = ref.read(
      walletRuntimeProvider.select((state) => state.knownAssets),
    );
    final name = knownAssets[asset]?.name ?? '';
    final ticker = knownAssets[asset]?.ticker ?? '';
    final decimals = knownAssets[asset]?.decimals ?? 0;
    final formattedAmount = formatCoin(amountAtomic, decimals, ticker);

    state = TransactionReviewState.burnTransaction(
      asset: asset,
      name: name,
      ticker: ticker,
      amount: formattedAmount,
      fee: formatXelis(feeAtomic, network),
      txHash: txHash,
      prepared: prepared,
      sessionIdentity: sessionIdentity,
    );
  }

  void setPreparedMultisigTransaction(
    wallet_flutter.XelisWalletPreparedTransaction prepared, {
    required Object sessionIdentity,
  }) {
    _requireActiveSession(sessionIdentity);
    final details = prepared.details;
    if (details is! wallet_flutter.XelisWalletPreparedMultisigTransaction) {
      throw ArgumentError.value(
        prepared,
        'prepared',
        'Expected finalized multisig details.',
      );
    }

    switch (details.transaction) {
      case wallet_flutter.XelisWalletMultisigTransfers(:final transfers):
        if (transfers.length != 1) {
          throw ArgumentError.value(
            prepared,
            'prepared',
            'Genesix review expects exactly one multisig transfer.',
          );
        }
        final transfer = transfers.single;
        _setSingleTransferTransaction(
          asset: transfer.asset,
          destination: transfer.destination,
          amountAtomic: transfer.amountAtomic,
          feeAtomic: prepared.feeAtomic,
          txHash: prepared.hash,
          prepared: prepared,
          sessionIdentity: sessionIdentity,
        );
      case wallet_flutter.XelisWalletMultisigBurn(
        :final asset,
        :final amountAtomic,
      ):
        _setBurnTransaction(
          asset: asset,
          amountAtomic: amountAtomic,
          feeAtomic: prepared.feeAtomic,
          txHash: prepared.hash,
          prepared: prepared,
          sessionIdentity: sessionIdentity,
        );
      case wallet_flutter.XelisWalletMultisigDelete():
        final network = ref.read(
          walletRuntimeProvider.select((state) => state.network),
        );
        state = TransactionReviewState.deleteMultisigTransaction(
          fee: formatXelis(prepared.feeAtomic, network),
          txHash: prepared.hash,
          prepared: prepared,
          sessionIdentity: sessionIdentity,
        );
    }
  }

  void setConfirmation(bool isConfirmed) {
    state = state.copyWith(isConfirmed: isConfirmed);
  }

  void broadcast() {
    state = state.copyWith(isBroadcasted: true);
  }

  void reset() {
    state = const TransactionReviewState.initial();
  }

  void _requireActiveSession(Object sessionIdentity) {
    if (!identical(ref.read(activeWalletRepositoryProvider), sessionIdentity)) {
      throw StateError(
        'Cannot install a transaction review for an inactive wallet session.',
      );
    }
  }
}
