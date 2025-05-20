// ignore_for_file: public_member_api_docs, invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

part 'event.freezed.dart';

@freezed
sealed class Event with _$Event {
  const factory Event.newTopoheight(int topoheight) = NewTopoHeight;

  const factory Event.newTransaction(TransactionEntry transactionEntry) =
      NewTransaction;

  const factory Event.balanceChanged(BalanceChangedEvent balanceChanged) =
      BalanceChanged;

  const factory Event.newAsset(RPCAssetData rpcAssetData) = NewAsset;

  const factory Event.rescan(int topoheight) = Rescan;

  const factory Event.online() = Online;

  const factory Event.offline() = Offline;

  const factory Event.historySynced(int topoheight) = HistorySynced;

  const factory Event.syncError(String message) = SyncError;

  const factory Event.trackAsset(String asset) = TrackAsset;

  const factory Event.untrackAsset(String asset) = UntrackAsset;
}
