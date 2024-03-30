import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/screens/wallet/data/node_addresses_state_repository.dart';
import 'package:xelis_mobile_wallet/screens/wallet/domain/node_addresses_state.dart';
import 'package:xelis_mobile_wallet/screens/wallet/domain/node_address.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_provider.dart';
import 'package:xelis_mobile_wallet/shared/storage/shared_preferences/shared_preferences_sync.dart';

part 'node_addresses_state_provider.g.dart';

@riverpod
class NodeAddresses extends _$NodeAddresses {
  @override
  NodeAddressesState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final nodeAddressesStateRepository =
        NodeAddressesStateRepository(SharedPreferencesSync(prefs));
    return nodeAddressesStateRepository.fromStorage();
  }

  void setNodeAddresses(NodeAddressesState nodeAddressesState) {
    final prefs = ref.read(sharedPreferencesProvider);
    final nodeAddressesStateRepository =
        NodeAddressesStateRepository(SharedPreferencesSync(prefs));
    state = nodeAddressesState;
    nodeAddressesStateRepository.localSave(state);
  }

  void setFavoriteAddress(NodeAddress address) {
    final prefs = ref.read(sharedPreferencesProvider);
    final nodeAddressesStateRepository =
        NodeAddressesStateRepository(SharedPreferencesSync(prefs));
    state = state.copyWith(favorite: address);
    nodeAddressesStateRepository.localSave(state);
  }

  void addNodeAddress(NodeAddress nodeAddress) {
    if (!state.nodeAddresses.contains(nodeAddress)) {
      final prefs = ref.read(sharedPreferencesProvider);
      final nodeAddressesStateRepository =
          NodeAddressesStateRepository(SharedPreferencesSync(prefs));
      state =
          state.copyWith(nodeAddresses: [...state.nodeAddresses, nodeAddress]);
      nodeAddressesStateRepository.localSave(state);
    }
  }

  void removeNodeAddress(NodeAddress nodeAddress) {
    if (state.nodeAddresses.contains(nodeAddress)) {
      final newNodeAddresses = [
        for (final item in state.nodeAddresses)
          if (item != nodeAddress) item,
      ];
      final prefs = ref.read(sharedPreferencesProvider);
      final nodeAddressesStateRepository =
          NodeAddressesStateRepository(SharedPreferencesSync(prefs));
      state = state.copyWith(nodeAddresses: newNodeAddresses);
      nodeAddressesStateRepository.localSave(state);
    }
  }
}
