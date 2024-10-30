// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coinpaprika/quotes.dart';

part 'xelis_ticker.freezed.dart';

part 'xelis_ticker.g.dart';

@freezed
class XelisTicker with _$XelisTicker {
  const XelisTicker._();

  const factory XelisTicker({
    required String id,
    required String name,
    required String symbol,
    required int rank,
    @JsonKey(name: 'total_supply') required int totalSupply,
    @JsonKey(name: 'max_supply') required int maxSupply,
    @JsonKey(name: 'beta_value') required double betaValue,
    @JsonKey(name: 'first_data_at') required DateTime firstDataAt,
    @JsonKey(name: 'last_updated') required DateTime lastUpdated,
    required Quotes quotes,
  }) = _XelisTicker;

  factory XelisTicker.fromJson(Map<String, dynamic> json) =>
      _$XelisTickerFromJson(json);

  double get price => quotes.usd.price;
}
