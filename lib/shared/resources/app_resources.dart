import 'package:flutter/widgets.dart';

class AppResources {
  static String localNodeAddress = '127.0.0.1:8080';

  /// TODO: ws and/or json_rpc
  static String officialRemoteNodeAddress = 'https://node.xelis.io';
  static String officialDevNode = 'https://dev-node.xelis.io/';
  static String officialTestnetNode = 'https://testnet-node.xelis.io/';

  static List<String> builtInNodeAddresses = [
    localNodeAddress,
    officialDevNode,
    officialTestnetNode,
  ];

  static List<String> languages = ['english', 'french'];

  static Image logoXelis = Image.asset(
    'assets/xelis_logo_pastille_01.png',
    fit: BoxFit.cover,
    height: 60,
  );

  static Image logoXelisHorizontal = Image.asset(
    'assets/xelis_logo_horizontal_color.png',
    fit: BoxFit.cover,
    height: 32,
  );
}
