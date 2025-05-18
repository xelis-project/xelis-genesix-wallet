// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'usd.freezed.dart';

part 'usd.g.dart';

@freezed
abstract class USD with _$USD {
  const factory USD({
    required double price,
    @JsonKey(name: 'volume_24h') required double volume24h,
    @JsonKey(name: 'volume_24h_change_24h') required double volume24hChange24h,
    @JsonKey(name: 'market_cap') required int marketCap,
    @JsonKey(name: 'market_cap_change_24h') required int marketCapChange24h,
    @JsonKey(name: 'percent_change_15m') required double percentChange15m,
    @JsonKey(name: 'percent_change_30m') required double percentChange30m,
    @JsonKey(name: 'percent_change_1h') required double percentChange1h,
    @JsonKey(name: 'percent_change_6h') required double percentChange6h,
    @JsonKey(name: 'percent_change_12h') required double percentChange12h,
    @JsonKey(name: 'percent_change_24h') required double percentChange24h,
    @JsonKey(name: 'percent_change_7d') required double percentChange7d,
    @JsonKey(name: 'percent_change_30d') required double percentChange30d,
    @JsonKey(name: 'percent_change_1y') required double percentChange1y,
    @JsonKey(name: 'ath_price') required double athPrice,
    @JsonKey(name: 'ath_date') required DateTime athDate,
    @JsonKey(name: 'percent_from_price_ath')
    required double percentFromPriceAth,
  }) = _USD;

  factory USD.fromJson(Map<String, dynamic> json) => _$USDFromJson(json);
}
