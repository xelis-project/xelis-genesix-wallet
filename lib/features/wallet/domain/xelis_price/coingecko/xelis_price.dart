// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'xelis_price.freezed.dart';

part 'xelis_price.g.dart';

@freezed
abstract class XelisPrice with _$XelisPrice {
  const factory XelisPrice({
    required double price,
    required double change24h,
    required String currencyCode,
    required String currencySymbol,
  }) = _XelisPrice;

  factory XelisPrice.fromJson(Map<String, dynamic> json) =>
      _$XelisPriceFromJson(json);
}
