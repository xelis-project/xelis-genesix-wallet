import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/src/generated/rust_bridge/api/models/network.dart';

class WalletSession {
  const WalletSession({required this.name, required this.repository});

  final String name;
  final NativeWalletRepository repository;

  String get address => repository.address;
  Network get network => repository.network;
}
