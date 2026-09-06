import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/invoke_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/transfer_builder_widget.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

const _canonicalAddress =
    'xel:qcd39a5u8cscztamjuyr7hdj6hh2wh9nrmhp86ljx2sz6t99ndjqqm7wxj8';

void main() {
  setUpAll(XelisWalletFlutter.initialize);

  testWidgets('attached data is summarized until its explicit reveal', (
    tester,
  ) async {
    final exactTail = 'exact-attached-data-tail';
    final longValue = '${List.filled(200000, 'a').join()}$exactTail';
    final wide = (BigInt.one << 255) + BigInt.from(123);
    DataElement attachedData = DataElement.fields({
      'wide': DataElement.value(RpcJsonValue.integer(wide)),
      'payload': DataElement.value(RpcJsonValue.string(longValue)),
    });
    for (var depth = 0; depth < 24; depth++) {
      attachedData = DataElement.array([attachedData]);
    }
    final builder = TransactionTypeBuilder.transfers(
      transfers: [
        TransferBuilder(
          asset: '0123456789abcdef0123456789abcdef',
          amount: BigInt.one,
          destination: _canonicalAddress,
          extraData: attachedData,
          encryptExtraData: false,
        ),
      ],
    ) as TransfersBuilder;

    await _pump(
      tester,
      TransfersBuilderWidget(
        transfersBuilder: builder,
        destinationDescriptors: [
          XelisWalletFlutter.parseAddress(address: _canonicalAddress),
        ],
      ),
    );

    expect(find.textContaining(exactTail), findsNothing);
    expect(
      find.byKey(const ValueKey('xswd-attached-data-preview-0')),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        '0123456789abcdef0123456789abcdef',
        findRichText: true,
      ),
      findsOneWidget,
    );

    final reveal = find.byKey(const ValueKey('xswd-attached-data-details-0'));
    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pump(const Duration(milliseconds: 150));

    final fullFinder = find.byKey(const ValueKey('xswd-attached-data-full-0'));
    expect(fullFinder, findsOneWidget);
    final full = tester.widget<XswdFullValueView>(fullFinder).value;
    expect(full, contains(wide.toString()));
    expect(full, contains(exactTail));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('RPC values reveal exact value and wire JSON on demand', (
    tester,
  ) async {
    final exactTail = 'exact-rpc-tail';
    final longValue = '${List.filled(200000, 'b').join()}$exactTail';
    RpcValueCell parameter = RpcValueCell.primitive(
      RpcPrimitive.string(longValue),
    );
    for (var depth = 0; depth < 24; depth++) {
      parameter = RpcValueCell.object([parameter]);
    }

    await _pump(
      tester,
      InvokeWidget(maxGas: BigInt.one, parameters: [parameter]),
    );

    expect(find.textContaining(exactTail), findsNothing);
    final parameterChip = find.byKey(const ValueKey('xswd-parameter-0'));
    expect(parameterChip, findsOneWidget);

    await tester.tap(parameterChip);
    await tester.pump(const Duration(milliseconds: 150));

    final fullFinder = find.byKey(const ValueKey('xswd-parameter-full-value'));
    expect(fullFinder, findsOneWidget);
    expect(
      tester.widget<XswdFullValueView>(fullFinder).value,
      contains(exactTail),
    );

    await tester.tap(
      find.byKey(const ValueKey('xswd-parameter-format-toggle')),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Raw JSON'), findsOneWidget);
    expect(
      tester.widget<XswdFullValueView>(fullFinder).value,
      contains(exactTail),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('large parameter roots use a virtualized disclosure list', (
    tester,
  ) async {
    final parameters = List<RpcValueCell>.generate(
      100,
      (index) => RpcValueCell.primitive(RpcPrimitive.u32(index)),
    );

    await _pump(
      tester,
      InvokeWidget(maxGas: BigInt.one, parameters: parameters),
    );

    expect(find.byKey(const ValueKey('xswd-parameter-23')), findsOneWidget);
    expect(find.byKey(const ValueKey('xswd-parameter-24')), findsNothing);
    final reveal = find.byKey(const ValueKey('xswd-all-parameters'));
    expect(reveal, findsOneWidget);

    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('100.'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
    ],
  );
  addTearDown(container.dispose);
  final theme = greenDark(touch: false);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.toApproximateMaterialTheme(),
        home: GenesixTheme(
          data: theme,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
}
