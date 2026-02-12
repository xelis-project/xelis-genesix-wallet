import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/display_currency.dart';
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

Uri coinGeckoEndpoint(String vsCurrency) => Uri.https(
  'api.coingecko.com',
  '/api/v3/simple/price',
  {'ids': 'xelis', 'vs_currencies': vsCurrency, 'include_24hr_change': 'true'},
);

Uri coinGecko24hMarketChartEndpoint(String vsCurrency) => Uri.https(
  'api.coingecko.com',
  '/api/v3/coins/xelis/market_chart',
  {'vs_currency': vsCurrency, 'days': '1'},
);

@riverpod
Future<XelisCoingeckoResponse> xelisPrice(Ref ref) async {
  final currencyCode = ref.watch(
    settingsProvider.select((state) => state.displayCurrency),
  );

  if (currencyCode == null) {
    throw StateError('No display currency selected');
  }

  final currency =
      DisplayCurrency.fromCode(currencyCode) ?? DisplayCurrency.usd;

  final timer = Timer(const Duration(seconds: 60), () => ref.invalidateSelf());
  final client = http.Client();

  ref.onDispose(() {
    timer.cancel();
    client.close();
  });

  final coinGeckoXelisResponse = await client.get(
    coinGeckoEndpoint(currency.code),
  );
  final coinGecko24hMarketChartResponse = await client.get(
    coinGecko24hMarketChartEndpoint(currency.code),
  );

  ref.keepAlive();

  final jsonXelisResponse =
      jsonDecode(coinGeckoXelisResponse.body) as Map<String, dynamic>;
  final xelisData = jsonXelisResponse['xelis'] as Map<String, dynamic>;

  final price = (xelisData[currency.code] as num).toDouble();
  final change24hKey = '${currency.code}_24h_change';
  final change24h = (xelisData[change24hKey] as num?)?.toDouble() ?? 0.0;

  final xelisPrice = XelisPrice(
    price: price,
    change24h: change24h,
    currencyCode: currency.code,
    currencySymbol: currency.symbol,
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
