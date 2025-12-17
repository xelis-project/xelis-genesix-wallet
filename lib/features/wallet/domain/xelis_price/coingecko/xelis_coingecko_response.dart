import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coingecko/xelis_price.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coingecko/xelis_price_point.dart';

part 'xelis_coingecko_response.freezed.dart';

part 'xelis_coingecko_response.g.dart';

@freezed
abstract class XelisCoingeckoResponse with _$XelisCoingeckoResponse {
  const XelisCoingeckoResponse._();

  const factory XelisCoingeckoResponse({
    required XelisPrice price,
    required List<XelisPricePoint> pricePoints,
  }) = _XelisCoingeckoResponse;

  factory XelisCoingeckoResponse.fromJson(Map<String, dynamic> json) =>
      _$XelisCoingeckoResponseFromJson(json);
}
