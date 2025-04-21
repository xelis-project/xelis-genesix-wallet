// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_filter_state.freezed.dart';

part 'history_filter_state.g.dart';

@freezed
abstract class HistoryFilterState with _$HistoryFilterState {
  const factory HistoryFilterState({
    @JsonKey(name: 'hide_extra_data') @Default(false) bool hideExtraData,
    @JsonKey(name: 'hide_zero_transfer') @Default(false) bool hideZeroTransfer,
    @JsonKey(name: 'show_incoming') @Default(true) bool showIncoming,
    @JsonKey(name: 'show_outgoing') @Default(true) bool showOutgoing,
    @JsonKey(name: 'show_coinbase') @Default(true) bool showCoinbase,
    @JsonKey(name: 'show_burn') @Default(true) bool showBurn,
    @JsonKey(name: 'asset') String? asset,
    @JsonKey(name: 'address') String? address,
  }) = _HistoryFilterState;

  factory HistoryFilterState.fromJson(Map<String, dynamic> json) =>
      _$HistoryFilterStateFromJson(json);
}
