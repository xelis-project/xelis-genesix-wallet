import 'package:freezed_annotation/freezed_annotation.dart';

part 'xelis_price_point.freezed.dart';

part 'xelis_price_point.g.dart';

@freezed
abstract class XelisPricePoint with _$XelisPricePoint {
  const XelisPricePoint._();

  const factory XelisPricePoint({
    required DateTime timestamp,
    required double price,
  }) = _XelisPricePoint;

  factory XelisPricePoint.fromList(List<dynamic> list) {
    return XelisPricePoint(
      timestamp: DateTime.fromMillisecondsSinceEpoch(list[0] as int),
      price: (list[1] as num).toDouble(),
    );
  }

  factory XelisPricePoint.fromJson(Map<String, dynamic> json) =>
      _$XelisPricePointFromJson(json);
}
