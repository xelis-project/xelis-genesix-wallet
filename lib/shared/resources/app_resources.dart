import 'package:flutter/widgets.dart';

class AppResources {
  static String localNodeAddress = '127.0.0.1:8080';
  static String officialNodeURL = 'node.xelis.io';
  static String officialDevNodeURL = 'dev-node.xelis.io';
  static String officialTestnetNodeURL = 'testnet-node.xelis.io';

  static List<String> builtInNodeAddresses = [
    localNodeAddress,
    officialNodeURL,
    officialDevNodeURL,
    officialTestnetNodeURL,
  ];

  static Image logoXelisLight = Image.asset(
    'assets/black_background_green_logo.png',
    fit: BoxFit.cover,
    height: 40,
  );

  static Image logoXelisDark = Image.asset(
    'assets/green_background_black_logo.png',
    fit: BoxFit.cover,
    height: 40,
  );

  static Image logoXelisHorizontal = Image.asset(
    'assets/transparent_background_green_logo.png',
    fit: BoxFit.cover,
    height: 32,
  );
}
