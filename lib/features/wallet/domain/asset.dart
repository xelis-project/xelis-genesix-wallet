import 'package:freezed_annotation/freezed_annotation.dart';

part 'asset.freezed.dart';

@freezed
class Asset with _$Asset {
  const Asset._();

  const factory Asset({
    required String hash,
    required String name,
    String? imagePath,
    String? imageURL,
    required int decimals,
    required String ticker,
  }) = _Asset;

  bool get isLocalImage => imagePath != null;

  bool get isNetworkImage => imageURL != null;
}
