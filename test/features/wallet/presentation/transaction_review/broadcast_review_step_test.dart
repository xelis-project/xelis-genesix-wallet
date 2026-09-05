import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/destination_address.dart';
import 'package:genesix/features/wallet/domain/transaction_review_state.dart';
import 'package:genesix/features/wallet/presentation/transaction_review/components/broadcast_review_step.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('explains an unconfirmed broadcast without broadcasting', (
    tester,
  ) async {
    var broadcastCount = 0;
    final container = await _pumpReview(
      tester,
      _review(hasExtraData: false, extraDataEncrypted: false),
      onBroadcast: (_) async {
        broadcastCount++;
      },
    );
    final toastSubscription = container.listen(
      toastProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(toastSubscription.close);

    final broadcastButton = find.widgetWithText(AsyncFButton, 'Broadcast');
    final foruiButton = tester.widget<FButton>(
      find.descendant(of: broadcastButton, matching: find.byType(FButton)),
    );
    foruiButton.onDisabledPress!();

    final toast = container.read(toastProvider);
    expect(toast?.title, 'Confirm');
    expect(toast?.description, contains('reviewed the transaction details'));
    expect(broadcastCount, 0);
  });

  testWidgets('keeps broadcast feedback inert while broadcasting', (
    tester,
  ) async {
    var broadcastCount = 0;
    final container = await _pumpReview(
      tester,
      _review(hasExtraData: false, extraDataEncrypted: false),
      isBroadcasting: true,
      onBroadcast: (_) async {
        broadcastCount++;
      },
    );

    final broadcastButton = find.widgetWithText(AsyncFButton, 'Broadcast');
    final foruiButton = tester.widget<FButton>(
      find.descendant(of: broadcastButton, matching: find.byType(FButton)),
    );
    expect(foruiButton.onPress, isNull);
    expect(foruiButton.onDisabledPress, isNull);

    expect(container.read(toastProvider), isNull);
    expect(broadcastCount, 0);
  });

  testWidgets('shows encrypted attached-data metadata from prepared details', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      _review(hasExtraData: true, extraDataEncrypted: true),
    );

    expect(find.text('Attached data'), findsOneWidget);
    expect(find.text('Encrypted'), findsOneWidget);
    expect(find.text('View attached data'), findsOneWidget);
    expect(find.text('Payment ID'), findsNothing);
  });

  testWidgets(
    'reveals prepared data only after an explicit capability-bound inspection',
    (tester) async {
      const secret = 'exchange-payment-reference';
      final repository = _FakeNativeWalletRepository(
        revealed: const XelisWalletPreparedTransferExtraData(
          data: XelisDataElement.value(XelisDataValue.string(secret)),
          source: XelisWalletPreparedExtraDataSource.integratedAddress,
          encrypted: true,
        ),
      );
      final review = _review(
        hasExtraData: true,
        extraDataEncrypted: true,
        sessionIdentity: repository,
      );

      await _pumpReview(tester, review, repository: repository);

      expect(repository.inspectCallCount, 0);
      expect(find.text(secret), findsNothing);

      await tester.tap(find.byKey(const ValueKey('view-attached-data')));
      await tester.pumpAndSettle();

      expect(repository.inspectCallCount, 1);
      expect(repository.lastTransferIndex, 0);
      expect(repository.lastPrepared, same(review.prepared));
      expect(find.text(secret), findsOneWidget);
      expect(find.text('Source: Integrated address'), findsOneWidget);
      expect(find.text('Encrypted'), findsWidgets);
    },
  );

  testWidgets('preserves a structured XWF failure in the error toast', (
    tester,
  ) async {
    const supportId = 'XWF-1111-2222-3333-4444-5555';
    const failure = XelisWalletOperationException(
      source: XelisWalletErrorSource.xelisWallet,
      operation: XelisWalletOperation.walletTransactionPreparedInspect,
      code: XelisWalletErrorCode.operationFailed,
      supportId: supportId,
      diagnosticMessage: 'attached payload must never reach the toast',
    );
    final repository = _FakeNativeWalletRepository(error: failure);
    final container = await _pumpReview(
      tester,
      _review(
        hasExtraData: true,
        extraDataEncrypted: true,
        sessionIdentity: repository,
      ),
      repository: repository,
    );
    final toastSubscription = container.listen(
      toastProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(toastSubscription.close);

    await tester.tap(find.byKey(const ValueKey('view-attached-data')));
    await tester.pumpAndSettle();

    final toast = container.read(toastProvider);
    expect(repository.inspectCallCount, 1);
    expect(toast?.supportReference, contains(supportId));
    expect(
      toast?.supportReference,
      contains('wallet.transaction.prepared.inspect'),
    );
    expect(
      toast?.supportReference,
      isNot(contains('attached payload must never reach')),
    );
  });

  testWidgets('shows when prepared attached data is not encrypted', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      _review(hasExtraData: true, extraDataEncrypted: false),
    );

    expect(find.text('Attached data'), findsOneWidget);
    expect(find.text('Not encrypted'), findsOneWidget);
  });

  testWidgets('prepared metadata overrides legacy integrated-address state', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      _review(
        hasExtraData: false,
        extraDataEncrypted: true,
        legacyIntegratedData: 'legacy-payment-reference',
      ),
    );

    expect(find.text('Attached data'), findsNothing);
    expect(find.text('legacy-payment-reference'), findsNothing);
  });
}

Future<ProviderContainer> _pumpReview(
  WidgetTester tester,
  SingleTransferTransaction review, {
  NativeWalletRepository? repository,
  bool isBroadcasting = false,
  Future<void> Function(WidgetRef)? onBroadcast,
}) async {
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      if (repository != null)
        activeWalletRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  final theme = greenDark(touch: false);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) => FTheme(data: theme, child: child!),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BroadcastReviewStep(
              review: review,
              isBroadcasting: isBroadcasting,
              onBroadcast: onBroadcast ?? (_) async {},
            ),
          ),
        ),
      ),
    ),
  );
  if (isBroadcasting) {
    await tester.pump(const Duration(milliseconds: 250));
  } else {
    await tester.pumpAndSettle();
  }
  return container;
}

SingleTransferTransaction _review({
  required bool hasExtraData,
  required bool extraDataEncrypted,
  Object? legacyIntegratedData,
  Object? sessionIdentity,
}) {
  final prepared = XelisWalletPreparedTransaction(
    hash: 'prepared-transfer-hash',
    feeAtomic: BigInt.one,
    details: XelisWalletPreparedTransfers(
      transfers: [
        XelisWalletPreparedTransfer(
          destination: _destination,
          asset: _asset,
          amountAtomic: BigInt.one,
          hasExtraData: hasExtraData,
          extraDataEncrypted: extraDataEncrypted,
        ),
      ],
    ),
  );

  return TransactionReviewState.singleTransferTransaction(
    asset: _asset,
    name: 'XELIS',
    ticker: 'XEL',
    amount: '1 XEL',
    fee: '0.00000001 XEL',
    destination: _destination,
    destinationAddress: DestinationAddress(
      address: _destination,
      data: legacyIntegratedData,
    ),
    txHash: prepared.hash,
    prepared: prepared,
    sessionIdentity: sessionIdentity ?? Object(),
  ) as SingleTransferTransaction;
}

const _destination = 'xel:prepared-review-destination';
const _asset =
    '0000000000000000000000000000000000000000000000000000000000000000';

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  _FakeNativeWalletRepository({this.revealed, this.error})
    : assert((revealed == null) != (error == null));

  final XelisWalletPreparedTransferExtraData? revealed;
  final Object? error;
  int inspectCallCount = 0;
  XelisWalletPreparedTransaction? lastPrepared;
  int? lastTransferIndex;

  @override
  Future<XelisWalletPreparedTransferExtraData> inspectPreparedTransferExtraData(
    XelisWalletPreparedTransaction transaction, {
    int transferIndex = 0,
  }) async {
    inspectCallCount += 1;
    lastPrepared = transaction;
    lastTransferIndex = transferIndex;
    if (error case final error?) throw error;
    return revealed!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
