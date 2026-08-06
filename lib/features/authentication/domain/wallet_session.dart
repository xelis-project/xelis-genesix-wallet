import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

class WalletSession {
  const WalletSession({required this.name, required this.repository});

  final String name;
  final NativeWalletRepository repository;

  String get address => repository.address;
  XelisNetwork get network => repository.network;
}
