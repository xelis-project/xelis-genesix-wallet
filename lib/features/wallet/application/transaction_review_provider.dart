import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/wallet_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/domain/transaction_summary.dart';
import 'package:genesix/shared/providers/provider_extensions.dart';
import 'package:genesix/shared/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_review_provider.g.dart';

@riverpod
class TransactionReview extends _$TransactionReview {
  @override
  TransactionReviewState build() {
    ref.cacheFor(Duration(seconds: 3));
    return TransactionReviewState.initial();
  }

  void signaturePending(String transactionHashToSign) {
    state = TransactionReviewState.signaturePending(
      hashToSign: transactionHashToSign,
    );
  }

  void setSingleTransferTransaction(TransactionSummary transactionSummary) {
    final network = ref.read(
      walletStateProvider.select((state) => state.network),
    );
    final transfer = transactionSummary.getSingleTransfer();
    final asset = transfer.asset;
    final destination = transfer.destination;
    final knownAssets = ref.read(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final name = knownAssets[asset]?.name ?? '';
    final ticker = knownAssets[asset]?.ticker ?? '';
    final decimals = knownAssets[asset]?.decimals ?? 0;
    final formattedAmount = formatCoin(transfer.amount, decimals, ticker);

    state = TransactionReviewState.singleTransferTransaction(
      isConfirmed: true,
      asset: asset,
      name: name,
      ticker: ticker,
      amount: formattedAmount,
      fee: formatXelis(transactionSummary.fee, network),
      destination: destination,
      destinationAddress: parseRawAddress(rawAddress: destination),
      txHash: transactionSummary.hash,
    );
  }

  Future<void> setBurnTransaction(TransactionSummary transactionSummary) async {
    final network = ref.read(
      walletStateProvider.select((state) => state.network),
    );
    final burn = transactionSummary.getBurn();
    final asset = burn.asset;
    final knownAssets = ref.read(
      walletStateProvider.select((state) => state.knownAssets),
    );
    final name = knownAssets[asset]?.name ?? '';
    final ticker = knownAssets[asset]?.ticker ?? '';
    final decimals = knownAssets[asset]?.decimals ?? 0;
    final formattedAmount = formatCoin(burn.amount, decimals, ticker);

    state = TransactionReviewState.burnTransaction(
      asset: asset,
      name: name,
      ticker: ticker,
      amount: formattedAmount,
      fee: formatXelis(transactionSummary.fee, network),
      txHash: transactionSummary.hash,
    );
  }

  void setDeleteMultisigTransaction(TransactionSummary transactionSummary) {
    final walletRepository = ref.read(
      walletStateProvider.select((state) => state.nativeWalletRepository),
    );
    if (walletRepository == null) {
      talker.warning('WalletRepository is not available');
      return;
    }

    state = TransactionReviewState.deleteMultisigTransaction(
      isConfirmed: true,
      fee: formatXelis(transactionSummary.fee, walletRepository.network),
      txHash: transactionSummary.hash,
    );
  }

  void setConfirmation(bool isConfirmed) {
    state = state.copyWith(isConfirmed: isConfirmed);
  }

  void broadcast() {
    state = state.copyWith(isBroadcasted: true);
  }
}
