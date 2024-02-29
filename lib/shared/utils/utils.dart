import 'dart:math';
import 'package:xelis_mobile_wallet/shared/resources/app_resources.dart';

String formatCoin(int value, int decimals) {
  return (value / pow(10, decimals)).toStringAsFixed(decimals);
}

String formatXelis(int value) {
  return formatCoin(value, AppResources.xelisDecimals);
}
