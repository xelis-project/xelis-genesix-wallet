import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/presentation/sign_transaction/components/signing_request_review.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('prioritizes the missing-participant feedback', (tester) async {
    var signCalls = 0;
    final harness = await _pumpReview(
      tester,
      request: _deleteRequest(),
      participant: null,
      isNodeAvailable: false,
      deleteConfirmed: false,
      onSign: () => signCalls++,
    );

    await _tapSign(tester, harness.loc);

    expect(signCalls, 0);
    expect(harness.toast?.title, harness.loc.not_available);
    expect(
      harness.toast?.description,
      harness.loc.wallet_not_multisig_participant,
    );
  });

  testWidgets('prioritizes node feedback over delete confirmation', (
    tester,
  ) async {
    var signCalls = 0;
    final harness = await _pumpReview(
      tester,
      request: _deleteRequest(),
      participant: _participants.first,
      isNodeAvailable: false,
      deleteConfirmed: false,
      onSign: () => signCalls++,
    );

    await _tapSign(tester, harness.loc);

    expect(signCalls, 0);
    expect(harness.toast?.title, harness.loc.not_available);
    expect(harness.toast?.description, _nodeRequirementMessage);
  });

  testWidgets('explains that delete confirmation is required', (tester) async {
    var signCalls = 0;
    final harness = await _pumpReview(
      tester,
      request: _deleteRequest(),
      participant: _participants.first,
      isNodeAvailable: true,
      deleteConfirmed: false,
      onSign: () => signCalls++,
    );

    await _tapSign(tester, harness.loc);

    expect(signCalls, 0);
    expect(harness.toast?.title, harness.loc.not_available);
    expect(
      harness.toast?.description,
      harness.loc.multisig_signing_delete_confirmation,
    );
  });

  testWidgets('keeps sign and disabled feedback inert while loading', (
    tester,
  ) async {
    var signCalls = 0;
    final harness = await _pumpReview(
      tester,
      request: _deleteRequest(),
      participant: _participants.first,
      isNodeAvailable: true,
      deleteConfirmed: false,
      isSigning: true,
      onSign: () => signCalls++,
    );

    await _tapSign(tester, harness.loc);

    expect(signCalls, 0);
    expect(harness.toast, isNull);
  });
}

const _nodeRequirementMessage = 'Connect to a node before signing.';
const _participants = [
  XelisWalletMultisigParticipant(id: 0, address: 'xel:participant-0'),
  XelisWalletMultisigParticipant(id: 1, address: 'xel:participant-1'),
];

XelisWalletMultisigSigningRequest _deleteRequest() {
  return XelisWalletMultisigSigningRequest(
    encoded: 'encoded-request',
    signingHash: 'signing-hash',
    source: 'xel:source-wallet',
    network: XelisNetwork.mainnet,
    feeAtomic: BigInt.one,
    feeLimitAtomic: BigInt.two,
    nonce: BigInt.zero,
    referenceTopoheight: BigInt.from(42),
    threshold: 2,
    participants: _participants,
    participantId: 0,
    transaction: const XelisWalletMultisigDelete(),
  );
}

WalletRuntimeState _runtime() {
  return WalletRuntimeState(
    topoheight: BigInt.from(42),
    xelisBalance: BigInt.zero,
    trackedBalances: LinkedHashMap(),
    knownAssets: LinkedHashMap(),
    address: 'xel:participant-0',
    name: 'Test wallet',
  );
}

Future<_ReviewHarness> _pumpReview(
  WidgetTester tester, {
  required XelisWalletMultisigSigningRequest request,
  required XelisWalletMultisigParticipant? participant,
  required bool isNodeAvailable,
  required bool deleteConfirmed,
  required VoidCallback onSign,
  bool isSigning = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final loc = AppLocalizationsEn();
  final container = ProviderContainer(
    overrides: [appLocalizationsProvider.overrideWithValue(loc)],
  );
  addTearDown(container.dispose);
  final theme = greenDark(touch: false);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.toApproximateMaterialTheme(),
        home: FTheme(
          data: theme,
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SigningRequestReview(
                  request: request,
                  runtime: _runtime(),
                  participant: participant,
                  isNodeAvailable: isNodeAvailable,
                  nodeRequirementMessage: _nodeRequirementMessage,
                  deleteConfirmed: deleteConfirmed,
                  isSigning: isSigning,
                  signingFailed: false,
                  onDeleteConfirmationChanged: (_) {},
                  onEdit: () {},
                  onSign: onSign,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return _ReviewHarness(container, loc);
}

Future<void> _tapSign(WidgetTester tester, AppLocalizationsEn loc) async {
  final button = find.widgetWithText(
    AsyncFButton,
    loc.sign_multisig_request_action,
  );
  expect(button, findsOneWidget);
  final foruiButton = tester.widget<FButton>(
    find.descendant(of: button, matching: find.byType(FButton)),
  );
  if (foruiButton.onDisabledPress case final onDisabledPress?) {
    onDisabledPress();
  }
}

final class _ReviewHarness {
  const _ReviewHarness(this.container, this.loc);

  final ProviderContainer container;
  final AppLocalizationsEn loc;

  dynamic get toast => container.read(toastProvider);
}
