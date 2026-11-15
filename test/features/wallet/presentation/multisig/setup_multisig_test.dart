import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/biometric_auth_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/wallet_commands_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/transaction_broadcast_result.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_setup_configuration.dart';
import 'package:genesix/features/wallet/presentation/multisig/components/setup/multisig_setup_review.dart';
import 'package:genesix/features/wallet/presentation/multisig/setup_multisig.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:material_ui/material_ui.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('failed discard retains the exact prepared review for retry', (
    tester,
  ) async {
    final harness = await _pumpSetup(tester);
    harness.commands.discardSucceeds = false;
    harness.review(tester).onEdit();
    await tester.pumpAndSettle();
    expect(harness.review(tester).hash, harness.commands.prepared.hash);
    expect(harness.commands.discarded, same(harness.commands.prepared));

    harness.commands.discardSucceeds = true;
    harness.review(tester).onEdit();
    await tester.pumpAndSettle();
    expect(find.byType(MultisigSetupConfiguration), findsOneWidget);
  });

  testWidgets(
    'authentication locks editing and broadcasts the reviewed capability',
    (tester) async {
      final harness = await _pumpSetup(tester);
      final review = harness.review(tester);
      review.onConfirmationChanged(true);
      await tester.pump();
      harness.review(tester).onActivate();
      await tester.pump();
      expect(harness.review(tester).isBroadcasting, isTrue);
      review.onEdit();
      await tester.pump();
      expect(harness.commands.discarded, isNull);

      harness.authentication.complete(true);
      await tester.pumpAndSettle();
      expect(harness.commands.broadcasted, same(harness.commands.prepared));
      expect(harness.commands.broadcastSession, same(harness.repository));
    },
  );

  testWidgets('wallet replacement during authentication prevents broadcast', (
    tester,
  ) async {
    final harness = await _pumpSetup(tester);
    harness.review(tester).onConfirmationChanged(true);
    await tester.pump();
    harness.review(tester).onActivate();
    await tester.pump();
    harness.replaceRepository();
    await tester.pump();
    harness.authentication.complete(true);
    await tester.pumpAndSettle();
    expect(harness.commands.broadcasted, isNull);
  });
}

class _Repository implements NativeWalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings extends Settings {
  @override
  SettingsState build() =>
      SettingsState(locale: const Locale('en'), activateBiometricAuth: true);
}

class _Runtime extends WalletRuntime {
  @override
  WalletRuntimeState build() => WalletRuntimeState(
    topoheight: BigInt.zero,
    xelisBalance: BigInt.zero,
    trackedBalances: LinkedHashMap(),
    knownAssets: LinkedHashMap(),
  );
}

class _Commands implements WalletCommandsController {
  final prepared = XelisWalletPreparedTransaction(
    hash: 'setup-hash',
    feeAtomic: BigInt.one,
    details: XelisWalletPreparedMultisigSetup(
      threshold: 1,
      participants: const [
        XelisWalletMultisigParticipant(id: 0, address: 'xel:participant'),
      ],
    ),
  );
  bool discardSucceeds = true;
  XelisWalletPreparedTransaction? discarded;
  XelisWalletPreparedTransaction? broadcasted;
  Object? broadcastSession;

  @override
  Future<XelisWalletPreparedTransaction?> setupMultisig({
    required List<String> participants,
    required int threshold,
  }) async => prepared;

  @override
  Future<bool> cancelPreparedTransaction({
    required XelisWalletPreparedTransaction transaction,
    required Object sessionIdentity,
  }) async {
    discarded = transaction;
    return discardSucceeds;
  }

  @override
  Future<PreparedTransactionBroadcastResult?> broadcastPreparedTx({
    required XelisWalletPreparedTransaction transaction,
    required Object sessionIdentity,
  }) async {
    broadcasted = transaction;
    broadcastSession = sessionIdentity;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Harness {
  _Harness(
    this.container,
    this.commands,
    this.authentication,
    this.repository,
    this.replaceRepository,
  );
  final ProviderContainer container;
  final _Commands commands;
  final Completer<bool> authentication;
  final _Repository repository;
  final void Function() replaceRepository;

  MultisigSetupReview review(WidgetTester tester) =>
      tester.widget(find.byType(MultisigSetupReview).last);
}

Future<_Harness> _pumpSetup(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final commands = _Commands();
  final authentication = Completer<bool>();
  final repository = _Repository();
  var currentRepository = repository;
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      walletRuntimeProvider.overrideWith(_Runtime.new),
      settingsProvider.overrideWith(_Settings.new),
      activeWalletRepositoryProvider.overrideWith((ref) => currentRepository),
      walletCommandsProvider.overrideWithValue(commands),
      biometricAuthenticationProvider.overrideWith(
        (ref, reason) => authentication.future,
      ),
    ],
  );
  addTearDown(container.dispose);
  final theme = greenDark(touch: false);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.toApproximateMaterialTheme(),
        home: GenesixTheme(data: theme, child: const SetupMultisig()),
      ),
    ),
  );
  tester
      .widget<MultisigSetupConfiguration>(
        find.byType(MultisigSetupConfiguration),
      )
      .onParticipantsChanged(['xel:participant']);
  await tester.pump();
  tester
      .widget<MultisigSetupConfiguration>(
        find.byType(MultisigSetupConfiguration),
      )
      .onPrepare();
  await tester.pumpAndSettle();
  return _Harness(container, commands, authentication, repository, () {
    currentRepository = _Repository();
    container.invalidate(activeWalletRepositoryProvider);
  });
}
