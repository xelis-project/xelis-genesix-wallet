import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/signature_collection_step.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('explains the unmet signature threshold', (tester) async {
    var finalizeCalls = 0;
    final harness = await _pumpCollection(
      tester,
      isFinalizing: false,
      onFinalize: (_) async => finalizeCalls++,
    );

    await _tapReview(tester, harness.loc);

    expect(finalizeCalls, 0);
    expect(harness.toast?.title, harness.loc.minimum_signatures_required);
    expect(
      harness.toast?.description,
      harness.loc.multisig_setup_threshold_summary(2, 2),
    );
  });

  testWidgets('keeps finalize and disabled feedback inert while finalizing', (
    tester,
  ) async {
    var finalizeCalls = 0;
    final harness = await _pumpCollection(
      tester,
      isFinalizing: true,
      onFinalize: (_) async => finalizeCalls++,
    );

    await _tapReview(tester, harness.loc);

    expect(finalizeCalls, 0);
    expect(harness.toast, isNull);
  });
}

const _participants = [
  XelisWalletMultisigParticipant(id: 0, address: 'xel:participant-0'),
  XelisWalletMultisigParticipant(id: 1, address: 'xel:participant-1'),
];

XelisWalletMultisigSigningRequest _request() {
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

Future<_CollectionHarness> _pumpCollection(
  WidgetTester tester, {
  required bool isFinalizing,
  required Future<void> Function(List<XelisWalletMultisigSignatureShare>)
  onFinalize,
}) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final loc = AppLocalizationsEn();
  final container = ProviderContainer(
    overrides: [appLocalizationsProvider.overrideWithValue(loc)],
  );
  final toastSubscription = container.listen(toastProvider, (_, _) {});
  addTearDown(toastSubscription.close);
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
                child: SignatureCollectionStep(
                  request: _request(),
                  isFinalizing: isFinalizing,
                  onFinalize: onFinalize,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  return _CollectionHarness(container, loc);
}

Future<void> _tapReview(WidgetTester tester, AppLocalizationsEn loc) async {
  final button = find.widgetWithText(AsyncFButton, loc.review);
  expect(button, findsOneWidget);
  final foruiButton = tester.widget<FButton>(
    find.descendant(of: button, matching: find.byType(FButton)),
  );
  if (foruiButton.onDisabledPress case final onDisabledPress?) {
    onDisabledPress();
  }
}

final class _CollectionHarness {
  const _CollectionHarness(this.container, this.loc);

  final ProviderContainer container;
  final AppLocalizationsEn loc;

  dynamic get toast => container.read(toastProvider);
}
