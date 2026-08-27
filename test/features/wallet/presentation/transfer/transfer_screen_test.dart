import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/presentation/transfer/transfer_screen.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('explains when no valid asset can be transferred', (
    tester,
  ) async {
    final harness = await _pumpTransfer(tester, runtime: _emptyRuntime());

    final button = await _tapDisabledReview(tester, harness.loc);

    expect(tester.widget<AsyncFButton>(button).onPress, isNull);
    expect(harness.toast?.title, harness.loc.no_balance_to_transfer);
  });

  testWidgets('asks for an asset after the selection is cleared', (
    tester,
  ) async {
    final harness = await _pumpTransfer(tester, runtime: _fundedRuntime());
    final formFields = find.descendant(
      of: find.byType(FTextFormField),
      matching: find.byType(EditableText),
    );
    expect(formFields, findsNWidgets(2));
    final editableTexts = tester.widgetList<EditableText>(formFields).toList();
    editableTexts[0].controller.text = '1.00';
    editableTexts[1].controller.text = 'xel:destination';
    _rebuildDirtyElements(tester);

    final enabledButton = find.widgetWithText(
      AsyncFButton,
      harness.loc.review_send,
    );
    expect(tester.widget<AsyncFButton>(enabledButton).onPress, isNotNull);

    final select = tester
        .widget<FSelect<MapEntry<String, XelisWalletAssetMetadata>>>(
          find.byWidgetPredicate(
            (widget) =>
                widget is FSelect<MapEntry<String, XelisWalletAssetMetadata>>,
          ),
        );
    final control =
        select.control!
            as FSelectManagedControl<
              MapEntry<String, XelisWalletAssetMetadata>
            >;
    control.controller!.value = null;
    control.onChange!(null);
    _rebuildDirtyElements(tester);

    final button = await _tapDisabledReview(tester, harness.loc);

    expect(tester.widget<AsyncFButton>(button).onPress, isNull);
    expect(harness.toast?.title, harness.loc.select_asset);
  });

  testWidgets('validates required fields without preparing a transaction', (
    tester,
  ) async {
    final harness = await _pumpTransfer(tester, runtime: _fundedRuntime());

    final button = await _tapDisabledReview(tester, harness.loc);

    expect(tester.widget<AsyncFButton>(button).onPress, isNull);
    expect(harness.toast, isNull);
    expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
  });
}

const _assetHash = 'asset-hash';
const _assetMetadata = XelisWalletAssetMetadata(
  name: 'Test asset',
  ticker: 'TST',
  decimals: 2,
  maxSupply: XelisWalletNoMaxSupply(),
  owner: XelisWalletNoAssetOwner(),
);

WalletRuntimeState _emptyRuntime() {
  return WalletRuntimeState(
    topoheight: BigInt.zero,
    xelisBalance: BigInt.zero,
    trackedBalances: LinkedHashMap(),
    knownAssets: LinkedHashMap(),
  );
}

WalletRuntimeState _fundedRuntime() {
  return WalletRuntimeState(
    topoheight: BigInt.zero,
    xelisBalance: BigInt.from(1000),
    trackedBalances: LinkedHashMap.of({_assetHash: BigInt.from(1000)}),
    knownAssets: LinkedHashMap.of({_assetHash: _assetMetadata}),
  );
}

Future<_TransferHarness> _pumpTransfer(
  WidgetTester tester, {
  required WalletRuntimeState runtime,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final loc = AppLocalizationsEn();
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(loc),
      walletRuntimeProvider.overrideWithValue(runtime),
    ],
  );
  addTearDown(container.dispose);
  final theme = greenDark(touch: false);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.toApproximateMaterialTheme(),
        home: FTheme(data: theme, child: const TransferScreen()),
      ),
    ),
  );

  return _TransferHarness(container, loc);
}

Future<Finder> _tapDisabledReview(
  WidgetTester tester,
  AppLocalizationsEn loc,
) async {
  final button = find.widgetWithText(AsyncFButton, loc.review_send);
  expect(button, findsOneWidget);
  final foruiButton = tester.widget<FButton>(
    find.descendant(of: button, matching: find.byType(FButton)),
  );
  foruiButton.onDisabledPress!();
  return button;
}

final class _TransferHarness {
  const _TransferHarness(this.container, this.loc);

  final ProviderContainer container;
  final AppLocalizationsEn loc;

  dynamic get toast => container.read(toastProvider);
}

void _rebuildDirtyElements(WidgetTester tester) {
  final binding = tester.binding;
  binding.buildOwner!.buildScope(binding.rootElement!);
}
