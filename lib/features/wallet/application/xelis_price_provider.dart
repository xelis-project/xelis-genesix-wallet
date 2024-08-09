import 'dart:async';
import 'dart:convert';

import 'package:genesix/features/wallet/domain/xelis_price/coinpaprika/xelis_ticker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

part 'xelis_price_provider.g.dart';

final Uri coinPaprikaEndpoint =
    Uri.https('api.coinpaprika.com', '/v1/tickers/xel-xelis');

@riverpod
Future<XelisTicker> xelisPrice(XelisPriceRef ref) async {
  final timer = Timer(const Duration(seconds: 60), () => ref.invalidateSelf());
  final client = http.Client();

  ref.onDispose(() {
    timer.cancel();
    client.close();
  });

  final response = await client.get(coinPaprikaEndpoint);

  ref.keepAlive();

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return XelisTicker.fromJson(json);
}
