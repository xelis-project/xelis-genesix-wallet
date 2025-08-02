import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coingecko/xelis_coingecko_response.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coingecko/xelis_price.dart';
import 'package:genesix/features/wallet/domain/xelis_price/coingecko/xelis_price_point.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

part 'xelis_price_provider.g.dart';

final Uri coinPaprikaEndpoint = Uri.https(
  'api.coinpaprika.com',
  '/v1/tickers/xel-xelis',
);

final Uri coinGeckoEndpoint = Uri.https(
  'api.coingecko.com',
  '/api/v3/simple/price',
  {'ids': 'xelis', 'vs_currencies': 'usd', 'include_24hr_change': 'true'},
);

final Uri coinGecko24hMarketChartEndpoint = Uri.https(
  'api.coingecko.com',
  '/api/v3/coins/xelis/market_chart',
  {'vs_currency': 'usd', 'days': '1'},
);

@riverpod
Future<XelisCoingeckoResponse> xelisPrice(Ref ref) async {
  final timer = Timer(const Duration(seconds: 60), () => ref.invalidateSelf());
  final client = http.Client();

  ref.onDispose(() {
    timer.cancel();
    client.close();
  });

  final coinGeckoXelisResponse = await client.get(coinGeckoEndpoint);
  final coinGecko24hMarketChartResponse = await client.get(
    coinGecko24hMarketChartEndpoint,
  );

  ref.keepAlive();

  final jsonXelisResponse =
      jsonDecode(coinGeckoXelisResponse.body) as Map<String, dynamic>;
  final xelisPrice = XelisPrice.fromJson(
    jsonXelisResponse['xelis'] as Map<String, dynamic>,
  );

  final xelisPricePointsRaw =
      (jsonDecode(coinGecko24hMarketChartResponse.body)
              as Map<String, dynamic>)['prices']
          as List<dynamic>;
  final xelisPricePoints = xelisPricePointsRaw
      .map((point) => XelisPricePoint.fromList(point as List<dynamic>))
      .toList();

  return XelisCoingeckoResponse(
    price: xelisPrice,
    pricePoints: xelisPricePoints,
  );
}
