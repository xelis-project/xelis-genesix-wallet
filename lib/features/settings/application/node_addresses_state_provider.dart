import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xelis_mobile_wallet/features/settings/data/node_addresses_state_repository.dart';
import 'package:xelis_mobile_wallet/features/settings/domain/node_addresses_state.dart';
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

  void setFavoriteAddress(String address) {
    final prefs = ref.read(sharedPreferencesProvider);
    final nodeAddressesStateRepository =
        NodeAddressesStateRepository(SharedPreferencesSync(prefs));
    state = state.copyWith(favorite: address);
    nodeAddressesStateRepository.localSave(state);
  }

  void addNodeAddress(String address) {
    if (!state.nodeAddresses.contains(address)) {
      final prefs = ref.read(sharedPreferencesProvider);
      final nodeAddressesStateRepository =
          NodeAddressesStateRepository(SharedPreferencesSync(prefs));
      state = state.copyWith(nodeAddresses: [...state.nodeAddresses, address]);
      nodeAddressesStateRepository.localSave(state);
    }
  }

  void removeNodeAddress(String address) {
    if (state.nodeAddresses.contains(address)) {
      final newNodeAddresses = [
        for (final item in state.nodeAddresses)
          if (item != address) item,
      ];
      final prefs = ref.read(sharedPreferencesProvider);
      final nodeAddressesStateRepository =
          NodeAddressesStateRepository(SharedPreferencesSync(prefs));
      state = state.copyWith(nodeAddresses: newNodeAddresses);
      nodeAddressesStateRepository.localSave(state);
    }
  }
}
