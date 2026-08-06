import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
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
  final repository = ref.watch(activeWalletRepositoryProvider);
  if (repository == null) {
    throw StateError('An active wallet session is required');
  }

  final detail = request.isPending
      ? TransactionEntryDetail.pending(
          await repository.pendingTransactionByHash(
            hash: request.hash,
            extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
          ),
        )
      : TransactionEntryDetail.confirmed(
          await repository.transactionByHash(
            hash: request.hash,
            extraDataDisclosure: XelisWalletExtraDataDisclosure.detailed,
          ),
        );

  if (!identical(ref.read(activeWalletRepositoryProvider), repository)) {
    throw StateError('The active wallet changed while loading transaction.');
  }

  if (detail.hash != request.hash || detail.isPending != request.isPending) {
    throw StateError('The loaded transaction detail does not match the route');
  }

  return detail;
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
