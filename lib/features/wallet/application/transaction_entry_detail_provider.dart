import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/application/wallet_history_refresh_signal_provider.dart';
import 'package:genesix/features/wallet/domain/transaction_entry_detail.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

final transactionEntryDetailProvider = FutureProvider.autoDispose
    .family<TransactionEntryDetail, TransactionEntryDetailRequest>(
      _loadTransactionEntryDetail,
    );

final transactionExactDestinationsProvider = FutureProvider.autoDispose
    .family<List<XelisAddressBookEntry?>, TransactionEntryDetailRequest>(
      _loadExactDestinations,
    );

Future<TransactionEntryDetail> _loadTransactionEntryDetail(
  Ref ref,
  TransactionEntryDetailRequest request,
) async {
  ref.watch(walletHistoryRefreshSignalProvider);
  final repository = ref.watch(activeWalletRepositoryProvider);
  if (repository == null) {
    throw StateError('An active wallet session is required');
  }

  final detail = request.isPending
      ? await _loadPendingOrConfirmedDetail(repository, request.hash)
      : TransactionEntryDetail.confirmed(
          await repository.transactionByHash(
            hash: request.hash,
            extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
          ),
        );

  if (!ref.mounted ||
      !identical(ref.read(activeWalletRepositoryProvider), repository)) {
    throw StateError('The active wallet changed while loading transaction.');
  }

  if (detail.hash != request.hash) {
    throw StateError('The loaded transaction detail does not match the route');
  }

  return detail;
}

Future<TransactionEntryDetail> _loadPendingOrConfirmedDetail(
  NativeWalletRepository repository,
  String hash,
) async {
  // A route's pending flag is an initial snapshot, not permanent authority over
  // status. Prefer confirmed storage, including when reopening an old route.
  try {
    return TransactionEntryDetail.confirmed(
      await repository.transactionByHash(
        hash: hash,
        extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
      ),
    );
  } on XelisWalletException catch (error) {
    if (error.code != XelisWalletErrorCode.notFound) rethrow;
  }

  try {
    return TransactionEntryDetail.pending(
      await repository.pendingTransactionByHash(
        hash: hash,
        extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
      ),
    );
  } on XelisWalletException catch (error) {
    if (error.code != XelisWalletErrorCode.notFound) rethrow;
    // Confirmation may move the transaction between the two reads.
    return TransactionEntryDetail.confirmed(
      await repository.transactionByHash(
        hash: hash,
        extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
      ),
    );
  }
}

Future<List<XelisAddressBookEntry?>> _loadExactDestinations(
  Ref ref,
  TransactionEntryDetailRequest request,
) async {
  final repository = ref.watch(activeWalletRepositoryProvider);
  if (repository == null) {
    throw StateError('An active wallet session is required');
  }

  final detail = await ref.watch(
    transactionEntryDetailProvider(request).future,
  );

  return switch (detail.entry) {
    XelisWalletOutgoingEntry(:final transfers) => Future.wait(
      transfers.map(
        (transfer) => _matchExactDestination(
          repository,
          baseAddress: transfer.destination,
          extraData: transfer.extraData,
        ),
      ),
    ),
    XelisWalletOutgoingBlobEntry(:final destinations, :final data) =>
      Future.wait(
        destinations.map(
          (destination) => _matchExactDestination(
            repository,
            baseAddress: destination,
            extraData: data,
          ),
        ),
      ),
    _ => const <XelisAddressBookEntry?>[],
  };
}

Future<XelisAddressBookEntry?> _matchExactDestination(
  NativeWalletRepository repository, {
  required String baseAddress,
  required XelisWalletExtraData? extraData,
}) async {
  // A null payload is ambiguous when an extra-data envelope exists: it may be
  // failed, unavailable, or redacted. Treating it as a standard destination
  // could incorrectly identify a contact that merely shares the base address.
  if (extraData != null && extraData.payload == null) {
    return null;
  }

  final match = await repository.matchAddressBookDestination(
    baseAddress: baseAddress,
    integratedData: extraData?.payload,
  );

  return switch (match) {
    XelisAddressBookExactMatch(:final entry) => entry,
    _ => null,
  };
}
