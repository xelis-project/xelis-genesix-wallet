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
    return TransactionReviewState();
  }

  void setTransactionHashToSign(String transactionHashToSign) {
    state = state.copyWith(transactionHashToSign: transactionHashToSign);
  }

  void setTransferSummary(TransactionSummary transactionSummary) async {
    final transfer = transactionSummary.getSingleTransfer();
    final atomicAmount = transfer.amount;
    final asset = transfer.asset;
    final destination = transfer.destination;
    final formattedAmount = ref
        .read(
            walletStateProvider.select((value) => value.nativeWalletRepository))
        ?.formatCoin(atomicAmount, asset);

    state = state.copyWith(
      summary: transactionSummary,
      isConfirmed: true,
      asset: asset,
      amount: formattedAmount,
      fee: formatXelis(transactionSummary.fee),
      destination: destination,
      walletAddress: getAddress(rawAddress: destination),
      finalHash: transactionSummary.hash,
    );
  }

  void setBurnSummary(TransactionSummary transactionSummary) {
    final burn = transactionSummary.getBurn();
    final asset = burn.asset;
    final amount = burn.amount;
    final formattedAmount = ref
        .read(
            walletStateProvider.select((value) => value.nativeWalletRepository))
        ?.formatCoin(amount, asset);

    state = state.copyWith(
      summary: transactionSummary,
      asset: asset,
      amount: formattedAmount,
      fee: formatXelis(transactionSummary.fee),
      finalHash: transactionSummary.hash,
    );
  }

  void setMultisigSummary(TransactionSummary transactionSummary) {
    state = state.copyWith(
      summary: transactionSummary,
      isConfirmed: true,
      fee: formatXelis(transactionSummary.fee),
      finalHash: transactionSummary.hash,
    );
  }

  void setConfirmation(bool isConfirmed) {
    state = state.copyWith(isConfirmed: isConfirmed);
  }

  void broadcast() {
    state = state.copyWith(isBroadcast: true);
  }
}
