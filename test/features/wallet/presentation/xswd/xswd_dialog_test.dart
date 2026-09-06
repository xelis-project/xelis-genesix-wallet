import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

import '../../../../helpers/xswd_test_payload.dart';

const _canonicalAddress =
    'xel:qcd39a5u8cscztamjuyr7hdj6hh2wh9nrmhp86ljx2sz6t99ndjqqm7wxj8';

void main() {
  setUpAll(XelisWalletFlutter.initialize);

  for (final method in ['get_balance', 'get_version', 'store']) {
    testWidgets('$method explains and binds remembered approval', (
      tester,
    ) async {
      final loc = AppLocalizationsEn();
      final container = ProviderContainer(
        overrides: [appLocalizationsProvider.overrideWithValue(loc)],
      );
      addTearDown(container.dispose);
      final decision = container
          .read(xswdRequestProvider.notifier)
          .newRequest(
            xswdEventSummary: XelisXswdRequest(
              kind: XelisXswdRequestKind.permission,
              application: _application,
              payload: xswdTestPayload({
                'id': 1,
                'jsonrpc': '2.0',
                'method': method,
              }),
            ),
            message: 'Review request',
          );
      final theme = greenDark(touch: false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme.toApproximateMaterialTheme(),
            home: GenesixTheme(
              data: theme,
              child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
            ),
          ),
        ),
      );
      final impact = switch (method) {
        'get_balance' => loc.xswd_permission_wallet_data_impact,
        'store' => loc.xswd_permission_app_storage_impact,
        _ => loc.xswd_permission_public_impact,
      };
      expect(find.text(impact).hitTestable(), findsOneWidget);
      expect(find.text(loc.xswd_permission_persistent_impact), findsNothing);
      expect(decision.isCompleted, isFalse);
      final remember = find.text(loc.remember_my_decision);
      await tester.ensureVisible(remember);
      await tester.tap(remember);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text(loc.xswd_permission_persistent_impact), findsOneWidget);
      expect(decision.isCompleted, isFalse);
      final allow = find.text(loc.allow);
      await tester.ensureVisible(allow);
      await tester.tap(allow);
      await tester.pump(const Duration(milliseconds: 150));
      expect(await decision.future, XelisXswdDecision.alwaysAccept);
      container.read(xswdRequestProvider.notifier).clearRequest();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  for (final viewport in <({Size size, double textScale})>[
    (size: const Size(320, 700), textScale: 1),
    (size: const Size(700, 900), textScale: 1),
    (size: const Size(700, 900), textScale: 2),
  ]) {
    testWidgets('shows transaction details before actions at '
        '${viewport.size.width}px and ${viewport.textScale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = viewport.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(xswdRequestProvider.notifier)
          .newRequest(
            xswdEventSummary: XelisXswdRequest(
              kind: XelisXswdRequestKind.permission,
              application: _application,
              payload: xswdTestPayload({
                'id': 1,
                'jsonrpc': '2.0',
                'method': WalletMethod.buildTransaction.jsonKey,
                'params': {
                  'transfers': [
                    {
                      'asset': 'asset-hash',
                      'amount': BigInt.parse('9007199254740993'),
                      'destination': _canonicalAddress,
                      'extra_data': {'wide': BigInt.parse('9007199254740993')},
                      'encrypt_extra_data': false,
                    },
                  ],
                  'fee': {'fixed': 7},
                  'base_fee': {'cap': 11},
                  'fee_limit': 13,
                  'broadcast': true,
                },
              }),
            ),
            message: 'Review request',
          );
      final theme = greenDark(touch: viewport.size.width < 600);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(viewport.textScale)),
              child: child!,
            ),
            theme: theme.toApproximateMaterialTheme(),
            home: GenesixTheme(
              data: theme,
              child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('xswd-transaction-review')),
        findsOneWidget,
      );
      expect(find.text(_canonicalAddress), findsOneWidget);
      expect(find.text('Attached data'), findsOneWidget);
      expect(find.textContaining('9007199254740993'), findsNothing);
      expect(
        find.textContaining('Not encrypted', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('7 atomic units'), findsOneWidget);
      expect(find.textContaining('11 atomic units'), findsOneWidget);
      expect(find.text('13 atomic units'), findsOneWidget);
      expect(find.text('Allow once'), findsOneWidget);
      expect(find.text('Remember my decision'), findsNothing);
      expect(
        find
            .byKey(const ValueKey('xswd-transaction-security-warning'))
            .hitTestable(),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('xswd-transaction-review')))
            .dy,
        lessThan(tester.getTopLeft(find.text('Allow once')).dy),
      );

      final attachedDataReveal = find.byKey(
        const ValueKey('xswd-attached-data-details-0'),
      );
      await tester.ensureVisible(attachedDataReveal);
      await tester.tap(attachedDataReveal);
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.textContaining('9007199254740993'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.takeException(), isNull);

      container.read(xswdRequestProvider.notifier).clearRequest();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('reveals typed integrated-address data only on explicit action', (
    tester,
  ) async {
    final wide = BigInt.parse('9007199254740993');
    final integrated = XelisWalletFlutter.makeIntegratedAddress(
      baseAddress: _canonicalAddress,
      integratedData: XelisDataElement.value(
        XelisDataValue.unsigned(
          type: XelisUnsignedIntegerType.u64,
          value: wide,
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(xswdRequestProvider.notifier)
        .newRequest(
          xswdEventSummary: XelisXswdRequest(
            kind: XelisXswdRequestKind.permission,
            application: _application,
            payload: xswdTestPayload({
              'id': 1,
              'jsonrpc': '2.0',
              'method': WalletMethod.buildTransaction.jsonKey,
              'params': {
                'transfers': [
                  {
                    'asset': 'asset-hash',
                    'amount': 1,
                    'destination': integrated.encodedAddress,
                    'encrypt_extra_data': false,
                  },
                ],
              },
            }),
          ),
          message: 'Review request',
        );
    final theme = greenDark(touch: false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme.toApproximateMaterialTheme(),
          home: GenesixTheme(
            data: theme,
            child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
          ),
        ),
      ),
    );

    expect(find.text(_canonicalAddress), findsOneWidget);
    expect(find.text(integrated.encodedAddress), findsNothing);
    expect(
      find.textContaining('Integrated address', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('u64', findRichText: true), findsOneWidget);
    expect(find.textContaining(wide.toString()), findsNothing);

    final reveal = find.byKey(
      const ValueKey('xswd-integrated-attached-data-details-0'),
    );
    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pump(const Duration(milliseconds: 150));

    final fullFinder = find.byKey(
      const ValueKey('xswd-integrated-attached-data-full-0'),
    );
    expect(fullFinder, findsOneWidget);
    final full = tester.widget<XswdFullValueView>(fullFinder).value;
    expect(full, contains(integrated.encodedAddress));
    expect(full, contains('u64(${wide.toString()})'));
    expect(tester.takeException(), isNull);

    container.read(xswdRequestProvider.notifier).clearRequest();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('reveals the serialized contract module on explicit action', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(xswdRequestProvider.notifier)
        .newRequest(
          xswdEventSummary: XelisXswdRequest(
            kind: XelisXswdRequestKind.permission,
            application: _application,
            payload: xswdTestPayload({
              'id': 1,
              'jsonrpc': '2.0',
              'method': WalletMethod.buildTransaction.jsonKey,
              'params': {
                'deploy_contract': {
                  'contract': '00aa',
                  'invoke': {
                    'max_gas': BigInt.parse('9007199254740993'),
                    'deposits': {
                      'asset-hash': {'amount': '7', 'private': true},
                    },
                  },
                },
              },
            }),
          ),
          message: 'Review request',
        );
    final theme = greenDark(touch: false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme.toApproximateMaterialTheme(),
          home: GenesixTheme(
            data: theme,
            child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
          ),
        ),
      ),
    );

    final reveal = find.byKey(const ValueKey('xswd-contract-module-details'));
    expect(reveal, findsOneWidget);
    expect(find.text('00aa'), findsNothing);
    expect(
      find.textContaining('9,007,199,254,740,993', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('7 asset-ha'), findsOneWidget);

    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('00aa'), findsOneWidget);
    expect(tester.takeException(), isNull);

    container.read(xswdRequestProvider.notifier).clearRequest();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('renders every fee and base-fee mode explicitly', (tester) async {
    final containers = <ProviderContainer>[];
    addTearDown(() {
      for (final container in containers) {
        container.dispose();
      }
    });
    final cases = <({Map<String, dynamic> fields, Map<String, int> expected})>[
      (fields: const {}, expected: const {'Calculated automatically': 2}),
      (
        fields: {
          'fee': {
            'extra': {'tip': '7'},
          },
          'base_fee': {'fixed': '11'},
        },
        expected: const {
          'Calculated automatically + 7 atomic units': 1,
          '11 atomic units': 1,
        },
      ),
      (
        fields: {
          'fee': {
            'extra': {'multiplier': 1.5},
          },
          'base_fee': {'cap': '11'},
          'fee_limit': '13',
        },
        expected: const {
          '1.5× base fee': 1,
          '≤ 11 atomic units': 1,
          '13 atomic units': 1,
        },
      ),
    ];

    for (final feeCase in cases) {
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
        ],
      );
      containers.add(container);
      container
          .read(xswdRequestProvider.notifier)
          .newRequest(
            xswdEventSummary: XelisXswdRequest(
              kind: XelisXswdRequestKind.permission,
              application: _application,
              payload: xswdTestPayload({
                'id': 1,
                'jsonrpc': '2.0',
                'method': WalletMethod.buildTransaction.jsonKey,
                'params': {
                  'burn': {'asset': 'asset-hash', 'amount': '1'},
                  ...feeCase.fields,
                },
              }),
            ),
            message: 'Review request',
          );
      final theme = greenDark(touch: false);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme.toApproximateMaterialTheme(),
            home: GenesixTheme(
              data: theme,
              child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
            ),
          ),
        ),
      );

      expect(find.text('Base fee'), findsOneWidget);
      for (final expected in feeCase.expected.entries) {
        expect(find.text(expected.key), findsNWidgets(expected.value));
      }
      expect(tester.takeException(), isNull);

      container.read(xswdRequestProvider.notifier).clearRequest();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('renders nested RPC values and wide gas exactly', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(xswdRequestProvider.notifier)
        .newRequest(
          xswdEventSummary: XelisXswdRequest(
            kind: XelisXswdRequestKind.permission,
            application: _application,
            payload: xswdTestPayload({
              'id': 1,
              'jsonrpc': '2.0',
              'method': WalletMethod.buildTransaction.jsonKey,
              'params': {
                'invoke_contract': {
                  'contract': 'contract-hash',
                  'max_gas': BigInt.parse('9007199254740993'),
                  'entry_id': 0,
                  'parameters': [
                    {
                      'type': 'object',
                      'value': [
                        {
                          'type': 'primitive',
                          'value': {'type': 'u64', 'value': '9007199254740993'},
                        },
                      ],
                    },
                  ],
                  'permission': 'none',
                },
              },
            }),
          ),
          message: 'Review request',
        );
    final theme = greenDark(touch: false);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme.toApproximateMaterialTheme(),
          home: GenesixTheme(
            data: theme,
            child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('9,007,199,254,740,993', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('[9007199254740993]'), findsOneWidget);
    expect(tester.takeException(), isNull);

    container.read(xswdRequestProvider.notifier).clearRequest();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows validated prefetch permissions before Allow', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(xswdRequestProvider.notifier)
        .newRequest(
          xswdEventSummary: XelisXswdRequest(
            kind: XelisXswdRequestKind.prefetchPermissions,
            application: _application,
            payload: xswdTestPayload({
              'reason': 'Show balances',
              'permissions': ['get_balance'],
            }),
          ),
          message: 'Review request',
        );
    final theme = greenDark(touch: false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme.toApproximateMaterialTheme(),
          home: GenesixTheme(
            data: theme,
            child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
          ),
        ),
      ),
    );

    expect(find.text('get_balance').hitTestable(), findsOneWidget);
    final loc = AppLocalizationsEn();
    expect(find.text(loc.xswd_permission_wallet_data_impact), findsOneWidget);
    expect(find.text(loc.xswd_permission_persistent_impact), findsOneWidget);
    expect(find.text('Allow').hitTestable(), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('get_balance')).dy,
      lessThan(tester.getTopLeft(find.text('Allow')).dy),
    );
    expect(tester.takeException(), isNull);

    container.read(xswdRequestProvider.notifier).clearRequest();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final _application = XelisXswdApplication(
  id: 'app-id',
  name: 'Test app',
  description: 'Test application',
  url: null,
  permissions: const {},
  isRelayer: false,
);
