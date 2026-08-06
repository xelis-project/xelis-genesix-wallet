import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test('preserves every persisted legacy network name', () {
    for (final network in XelisNetwork.values) {
      final state = SettingsState.fromJson({
        'locale': '{"language_code":"en","country_code":null}',
        'network': network.name,
      });

      expect(state.network, network);
      expect(state.toJson()['network'], network.name);
    }
  });
}
