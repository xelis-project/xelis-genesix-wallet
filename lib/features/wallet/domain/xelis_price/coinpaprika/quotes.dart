// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coinpaprika/usd.dart';

part 'quotes.freezed.dart';

part 'quotes.g.dart';

@freezed
class Quotes with _$Quotes {
  const factory Quotes({
    @JsonKey(name: 'USD') required USD usd,
  }) = _Quotes;

  factory Quotes.fromJson(Map<String, dynamic> json) => _$QuotesFromJson(json);
}
