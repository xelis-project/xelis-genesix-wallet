import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/application/xswd_decision_timing.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/xswd_method_policy.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_inter_contract_permission_review.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog_host.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_permission_copy.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:genesix/src/generated/l10n/app_localizations_fr.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

import '../../../../helpers/xswd_test_payload.dart';

const _canonicalAddress =
    'xel:qcd39a5u8cscztamjuyr7hdj6hh2wh9nrmhp86ljx2sz6t99ndjqqm7wxj8';
const _contractHash =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const _calledContractHash =
    'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210';

void main() {
  setUpAll(XelisWalletFlutter.initialize);

  for (final reviewCase in <({String method, String? event})>[
    (method: 'get_balance', event: null),
    (method: 'get_version', event: null),
    (method: 'store', event: null),
    (method: 'subscribe', event: 'balance_changed'),
    (method: 'unsubscribe', event: 'new_transaction'),
  ]) {
    final method = reviewCase.method;
    testWidgets('$method explains explicit connection-scoped approval', (
      tester,
    ) async {
      final loc = AppLocalizationsEn();
      final harness = _XswdTestHarness(loc);
      final container = harness.container;
      addTearDown(container.dispose);
      final decision = harness.newRequest(
        XelisXswdRequest(
          kind: XelisXswdRequestKind.permission,
          application: _application,
          payload: xswdTestPayload({
            'id': 1,
            'jsonrpc': '2.0',
            'method': method,
            if (reviewCase.event case final event?) 'params': {'notify': event},
          }),
        ),
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
      final review = container.read(xswdRequestProvider).permissionReview!;
      expect(
        find.text(xswdPermissionActionLabel(method, loc)).hitTestable(),
        findsOneWidget,
      );
      expect(find.text(method).hitTestable(), findsNothing);
      if (reviewCase.event case final event?) {
        expect(
          find
              .text(
                loc.xswd_recent_event(
                  xswdWalletEventLabel(WalletEvent.fromStr(event), loc),
                ),
              )
              .hitTestable(),
          findsOneWidget,
        );
      }
      expect(container.read(xswdRequestProvider).pending, isTrue);
      expect(find.text(loc.xswd_allow_once), findsOneWidget);
      expect(find.text(loc.xswd_deny_once), findsOneWidget);
      final connectionScope = find.text(loc.xswd_scope_connection);
      await tester.ensureVisible(connectionScope);
      await tester.tap(connectionScope);
      await tester.pump(const Duration(milliseconds: 150));
      if (review.subscriptionEvent != null) {
        final note = xswdPermissionConsentNote(method, loc)!;
        await tester.ensureVisible(find.text(note));
        expect(find.text(note).hitTestable(), findsOneWidget);
      }
      expect(container.read(xswdRequestProvider).pending, isTrue);
      expect(find.text(loc.xswd_block_for_connection), findsOneWidget);
      final allow = find.text(loc.xswd_allow_for_connection);
      await tester.ensureVisible(allow);
      await tester.tap(allow);
      await tester.pump(const Duration(milliseconds: 150));
      expect(await decision, XelisXswdDecision.alwaysAccept);
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
      final harness = _XswdTestHarness(AppLocalizationsEn());
      final container = harness.container;
      addTearDown(container.dispose);
      harness.newRequest(
        XelisXswdRequest(
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
    final harness = _XswdTestHarness(AppLocalizationsEn());
    final container = harness.container;
    addTearDown(container.dispose);
    harness.newRequest(
      XelisXswdRequest(
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
    final harness = _XswdTestHarness(AppLocalizationsEn());
    final container = harness.container;
    addTearDown(container.dispose);
    harness.newRequest(
      XelisXswdRequest(
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
      final harness = _XswdTestHarness(AppLocalizationsEn());
      final container = harness.container;
      containers.add(container);
      harness.newRequest(
        XelisXswdRequest(
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
    final harness = _XswdTestHarness(AppLocalizationsEn());
    final container = harness.container;
    addTearDown(container.dispose);
    harness.newRequest(
      XelisXswdRequest(
        kind: XelisXswdRequestKind.permission,
        application: _application,
        payload: xswdTestPayload({
          'id': 1,
          'jsonrpc': '2.0',
          'method': WalletMethod.buildTransaction.jsonKey,
          'params': {
            'invoke_contract': {
              'contract': _contractHash,
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

  testWidgets('renders the exact top-level inter-contract authority', (
    tester,
  ) async {
    final loc = AppLocalizationsEn();
    final cases =
        <({String name, Object permission, String description, bool broad})>[
          (
            name: 'none',
            permission: 'none',
            description: loc.xswd_inter_contract_none_description,
            broad: false,
          ),
          (
            name: 'all',
            permission: 'all',
            description: loc.xswd_inter_contract_effective_all,
            broad: true,
          ),
          (
            name: 'specific',
            permission: {'specific': <Object>[]},
            description: loc.xswd_inter_contract_specific_empty,
            broad: false,
          ),
          (
            name: 'exclude',
            permission: {'exclude': <Object>[]},
            description: loc.xswd_inter_contract_exclude_empty,
            broad: true,
          ),
        ];

    for (final (index, reviewCase) in cases.indexed) {
      final harness = _XswdTestHarness(loc);
      final container = harness.container;
      addTearDown(container.dispose);
      final decision = harness.newRequest(
        _invokePermissionRequest(
          id: index + 1,
          permission: reviewCase.permission,
        ),
      );
      await _pumpXswdDialog(tester, container);

      final permission = find.byKey(
        const ValueKey('xswd-inter-contract-permission'),
      );
      final payload = find.byKey(
        const ValueKey('xswd-permission-payload-container'),
      );
      expect(permission, findsOneWidget);
      expect(find.text(reviewCase.name), findsOneWidget);
      expect(find.text(reviewCase.description), findsOneWidget);
      expect(
        find.text(loc.xswd_inter_contract_transaction_scope),
        findsOneWidget,
      );
      expect(
        find.descendant(of: payload, matching: permission),
        findsOneWidget,
      );

      final broadWarning = find.byKey(
        const ValueKey('xswd-inter-contract-broad-warning'),
      );
      if (reviewCase.broad) {
        expect(broadWarning, findsOneWidget);
        expect(
          find.text(loc.xswd_inter_contract_broad_warning),
          findsOneWidget,
        );
        expect(
          find.descendant(of: payload, matching: broadWarning),
          findsNothing,
        );
        expect(
          tester.getTopLeft(broadWarning).dy,
          lessThan(tester.getTopLeft(payload).dy),
        );
      } else {
        expect(broadWarning, findsNothing);
      }

      final token = container.read(xswdRequestProvider).token!;
      container.read(xswdRequestProvider.notifier).rejectIfCurrent(token);
      expect(await decision, XelisXswdDecision.reject);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('explains exact nested and inverted function selectors', (
    tester,
  ) async {
    final loc = AppLocalizationsEn();
    final cases =
        <
          ({
            String name,
            Object permission,
            String selector,
            String effective,
            String? functions,
          })
        >[
          (
            name: 'specific all',
            permission: _listedPermission(outer: 'specific', chunk: 'all'),
            selector: 'all',
            effective: loc.xswd_inter_contract_effective_all,
            functions: null,
          ),
          (
            name: 'specific only',
            permission: _listedPermission(
              outer: 'specific',
              chunk: {
                'specific': [1, 65535],
              },
            ),
            selector: 'specific',
            effective: loc.xswd_inter_contract_effective_only,
            functions: '1, 65535',
          ),
          (
            name: 'specific except',
            permission: _listedPermission(
              outer: 'specific',
              chunk: {
                'exclude': [1, 65535],
              },
            ),
            selector: 'exclude',
            effective: loc.xswd_inter_contract_effective_except,
            functions: '1, 65535',
          ),
          (
            name: 'exclude all becomes none',
            permission: _listedPermission(outer: 'exclude', chunk: 'all'),
            selector: 'all',
            effective: loc.xswd_inter_contract_effective_none,
            functions: null,
          ),
          (
            name: 'exclude specific becomes except',
            permission: _listedPermission(
              outer: 'exclude',
              chunk: {
                'specific': [1, 65535],
              },
            ),
            selector: 'specific',
            effective: loc.xswd_inter_contract_effective_except,
            functions: '1, 65535',
          ),
          (
            name: 'double exclude becomes only',
            permission: _listedPermission(
              outer: 'exclude',
              chunk: {
                'exclude': [1, 65535],
              },
            ),
            selector: 'exclude',
            effective: loc.xswd_inter_contract_effective_only,
            functions: '1, 65535',
          ),
        ];

    for (final (index, reviewCase) in cases.indexed) {
      final harness = _XswdTestHarness(loc);
      final container = harness.container;
      addTearDown(container.dispose);
      final decision = harness.newRequest(
        _invokePermissionRequest(
          id: 100 + index,
          permission: reviewCase.permission,
        ),
      );
      await _pumpXswdDialog(tester, container);

      final rule = find.byKey(const ValueKey('xswd-inter-contract-rule-0'));
      expect(rule, findsOneWidget, reason: reviewCase.name);
      await tester.ensureVisible(rule);
      await tester.tap(rule);
      await tester.pump(const Duration(milliseconds: 150));

      final detailDialog = find.byKey(
        const ValueKey('xswd-inter-contract-rule-dialog-0'),
      );
      expect(find.text(_calledContractHash), findsOneWidget);
      expect(
        find.descendant(
          of: detailDialog,
          matching: find.text(reviewCase.selector),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detailDialog,
          matching: find.text(reviewCase.effective),
        ),
        findsOneWidget,
      );
      if (reviewCase.functions case final functions?) {
        expect(find.text(functions), findsOneWidget);
      } else {
        expect(
          find.byKey(const ValueKey('xswd-inter-contract-functions-0')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(loc.close));
      await tester.pump(const Duration(milliseconds: 150));
      final token = container.read(xswdRequestProvider).token!;
      container.read(xswdRequestProvider.notifier).rejectIfCurrent(token);
      expect(await decision, XelisXswdDecision.reject);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('keeps permission review first and localized at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loc = AppLocalizationsEn();
    final harness = _XswdTestHarness(loc);
    final container = harness.container;
    addTearDown(container.dispose);
    final decision = harness.newRequest(
      _invokePermissionRequest(
        id: 200,
        permission: _listedPermission(
          outer: 'specific',
          chunk: {
            'exclude': [1, 65535],
          },
        ),
        parameters: List.generate(
          24,
          (index) => {
            'type': 'primitive',
            'value': {'type': 'u16', 'value': index},
          },
        ),
      ),
    );
    await _pumpXswdDialog(tester, container);

    final permission = find.byKey(
      const ValueKey('xswd-inter-contract-permission'),
    );
    final maxGas = find.textContaining(loc.max_gas, findRichText: true);
    expect(find.text(loc.xswd_inter_contract_title), findsOneWidget);
    expect(find.text(loc.xswd_inter_contract_unlisted_none), findsOneWidget);
    expect(permission, findsOneWidget);
    expect(maxGas, findsOneWidget);
    expect(
      tester.getTopLeft(permission).dy,
      lessThan(tester.getTopLeft(maxGas).dy),
    );
    expect(tester.takeException(), isNull);

    final token = container.read(xswdRequestProvider).token!;
    container.read(xswdRequestProvider.notifier).rejectIfCurrent(token);
    expect(await decision, XelisXswdDecision.reject);
    await tester.pumpWidget(const SizedBox.shrink());

    final translated = AppLocalizationsFr();
    final theme = greenDark(touch: true);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        theme: theme.toApproximateMaterialTheme(),
        home: GenesixTheme(
          data: theme,
          child: Scaffold(
            body: SingleChildScrollView(
              child: XswdInterContractPermissionReview(
                permission: InterContractPermission.fromJson(
                  _listedPermission(
                    outer: 'specific',
                    chunk: {
                      'exclude': [1, 65535],
                    },
                  ),
                ),
                loc: translated,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text(translated.xswd_inter_contract_title), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      find.byKey(const ValueKey('xswd-inter-contract-rule-dialog-0')),
      findsOneWidget,
    );
    expect(find.text(_calledContractHash), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups a mixed prefetch and grants only the selection', (
    tester,
  ) async {
    final harness = _XswdTestHarness(AppLocalizationsEn());
    final container = harness.container;
    addTearDown(container.dispose);
    final decision = harness.newPrefetchRequest(
      XelisXswdRequest(
        kind: XelisXswdRequestKind.prefetchPermissions,
        application: _application,
        payload: xswdTestPayload({
          'reason': 'Show balances',
          'permissions': [
            'get_balance',
            'network_info',
            'store',
            'build_transaction',
          ],
        }),
      ),
      currentPermissions: const {
        'get_balance': XelisXswdPermissionPolicy.ask,
        'network_info': XelisXswdPermissionPolicy.accept,
        'store': XelisXswdPermissionPolicy.reject,
        'build_transaction': XelisXswdPermissionPolicy.ask,
      },
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
    expect(tester.takeException(), isNull);

    final loc = AppLocalizationsEn();
    expect(find.text('get_balance').hitTestable(), findsNothing);
    expect(find.text('Show balances').hitTestable(), findsNothing);
    expect(
      find.text(loc.xswd_prefetch_already_allowed_count(1)),
      findsOneWidget,
    );
    expect(find.text(loc.xswd_transaction_each_time), findsOneWidget);
    expect(find.text(loc.xswd_prefetch_allow_count(1)), findsOneWidget);
    expect(
      find.text(loc.xswd_prefetch_continue_without_new_permissions),
      findsOneWidget,
    );
    final rejectedCopy = xswdPermissionCopy(
      'store',
      tryXswdMethodPolicyForKey('store'),
      loc,
    );
    final blockedCheckbox = find.widgetWithText(FCheckbox, rejectedCopy.title);
    await tester.ensureVisible(blockedCheckbox);
    await tester.tap(blockedCheckbox);
    await tester.pump(const Duration(milliseconds: 150));
    final allow = find.text(loc.xswd_prefetch_allow_count(2));
    await tester.ensureVisible(allow);
    expect(
      tester.getTopLeft(find.text(loc.xswd_action_read_balance)).dy,
      lessThan(tester.getTopLeft(allow).dy),
    );
    await tester.tap(allow);
    await tester.pump(const Duration(milliseconds: 150));
    final result = await decision;
    expect(result, isA<XelisXswdPrefetchGrant>());
    expect((result as XelisXswdPrefetchGrant).permissions, [
      'get_balance',
      'store',
    ]);
    expect(tester.takeException(), isNull);

    container.read(xswdRequestProvider.notifier).clearRequest();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final loc in [AppLocalizationsEn(), AppLocalizationsFr()]) {
    testWidgets(
      'large batch remains readable at 320px with double text (${loc.localeName})',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = _XswdTestHarness(loc);
        final container = harness.container;
        addTearDown(container.dispose);
        final methods = [
          'subscribe',
          ...WalletMethod.values
              .map((method) => method.jsonKey)
              .where(
                (method) =>
                    tryXswdMethodPolicyForKey(method)?.canPrefetch == true,
              )
              .take(18),
        ];
        final decision = harness.newPrefetchRequest(
          _prefetchRequest(permissions: methods),
          currentPermissions: const {},
        );
        final theme = greenDark(touch: true);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: theme.toApproximateMaterialTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: GenesixTheme(
                data: theme,
                child: const Scaffold(
                  body: XswdDialog(kAlwaysCompleteAnimation),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text(loc.xswd_requested_permissions).hitTestable(),
          findsOneWidget,
        );
        expect(
          find
              .text(loc.xswd_prefetch_allow_count(methods.length))
              .hitTestable(),
          findsOneWidget,
        );
        final privacy = find.text(loc.xswd_subscription_connection_notice);
        await tester.ensureVisible(privacy);
        expect(privacy.hitTestable(at: Alignment.topCenter), findsOneWidget);
        expect(find.text('subscribe').hitTestable(), findsNothing);
        await tester.tap(
          find.text(loc.xswd_prefetch_continue_without_new_permissions),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(await decision, isA<XelisXswdPrefetchNoChange>());
        container.read(xswdRequestProvider.notifier).clearRequest();
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a replacement batch resets selection for the captured rules', (
    tester,
  ) async {
    final loc = AppLocalizationsEn();
    final harness = _XswdTestHarness(loc);
    final container = harness.container;
    addTearDown(container.dispose);
    final firstDecision = harness.newPrefetchRequest(
      _prefetchRequest(permissions: const ['subscribe']),
      currentPermissions: const {'subscribe': XelisXswdPermissionPolicy.ask},
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
    final subscribeTitle = xswdPermissionCopy(
      'subscribe',
      tryXswdMethodPolicyForKey('subscribe'),
      loc,
    ).title;
    expect(
      tester
          .widget<FCheckbox>(find.widgetWithText(FCheckbox, subscribeTitle))
          .value,
      isTrue,
    );

    final secondDecision = harness.newPrefetchRequest(
      _prefetchRequest(permissions: const ['subscribe']),
      currentPermissions: const {'subscribe': XelisXswdPermissionPolicy.reject},
    );
    await tester.pump();

    expect(await firstDecision, isA<XelisXswdPrefetchNoChange>());
    expect(
      tester
          .widget<FCheckbox>(find.widgetWithText(FCheckbox, subscribeTitle))
          .value,
      isFalse,
    );
    expect(find.text(loc.xswd_prefetch_previously_blocked), findsOneWidget);
    container.read(xswdRequestProvider.notifier).clearRequest();
    expect(await secondDecision, isA<XelisXswdPrefetchNoChange>());
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stale actions and the old close timer cannot resolve a replacement',
    (tester) async {
      final loc = AppLocalizationsEn();
      final harness = _XswdTestHarness(loc);
      final container = harness.container;
      addTearDown(container.dispose);
      final presentedTokens = <Object>[];
      final firstDecision = harness.newRequest(
        _permissionRequest(id: 1, method: 'get_balance'),
      );
      final firstToken = container.read(xswdRequestProvider).token!;
      final theme = greenDark(touch: false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme.toApproximateMaterialTheme(),
            home: GenesixTheme(
              data: theme,
              child: Scaffold(
                body: XswdDialog(
                  kAlwaysCompleteAnimation,
                  onRequestPresented: presentedTokens.add,
                ),
              ),
            ),
          ),
        ),
      );

      expect(presentedTokens.single, same(firstToken));
      await tester.tap(find.text(loc.xswd_scope_connection));
      await tester.pump(const Duration(milliseconds: 150));
      final oldAllowButton = tester.widget<FButton>(
        find.widgetWithText(FButton, loc.xswd_allow_for_connection),
      );
      oldAllowButton.onPress?.call();
      await tester.pump();
      expect(await firstDecision, XelisXswdDecision.alwaysAccept);

      final secondDecision = harness.newRequest(
        _permissionRequest(id: 2, method: 'get_version'),
      );
      final secondToken = container.read(xswdRequestProvider).token!;
      expect(identical(firstToken, secondToken), isFalse);
      await tester.pump();

      expect(presentedTokens.last, same(secondToken));
      expect(find.text(loc.xswd_scope_once), findsOneWidget);
      expect(find.text(loc.xswd_allow_once), findsOneWidget);
      expect(
        tester
            .widget<FRadio>(find.widgetWithText(FRadio, loc.xswd_scope_once))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<FRadio>(
              find.widgetWithText(FRadio, loc.xswd_scope_connection),
            )
            .value,
        isFalse,
      );
      expect(container.read(xswdRequestProvider).suppressXswdToast, isFalse);

      oldAllowButton.onPress?.call();
      await tester.pump(const Duration(milliseconds: 600));

      final state = container.read(xswdRequestProvider);
      expect(state.token, same(secondToken));
      expect(state.pending, isTrue);
      expect(find.byType(XswdDialog), findsOneWidget);

      container.read(xswdRequestProvider.notifier).rejectIfCurrent(secondToken);
      expect(await secondDecision, XelisXswdDecision.reject);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps the approval pending when no navigator is available', (
    tester,
  ) async {
    final harness = _XswdTestHarness(AppLocalizationsEn());
    final container = harness.container;
    addTearDown(container.dispose);
    final decision = harness.newRequest(
      _permissionRequest(id: 1, method: 'get_balance'),
    );
    final token = container.read(xswdRequestProvider).token!;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const XswdDialogHost(child: SizedBox.shrink()),
      ),
    );
    expect(
      container.read(xswdRequestProvider.notifier).requestOpenIfCurrent(token),
      isTrue,
    );
    await tester.pump();

    expect(container.read(xswdRequestProvider).token, same(token));
    expect(container.read(xswdRequestProvider).pending, isTrue);
    expect(
      container.read(xswdDialogCoordinatorProvider).presentedToken,
      isNull,
    );

    container.read(xswdRequestProvider.notifier).rejectIfCurrent(token);
    expect(await decision, XelisXswdDecision.reject);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('late opening and reopening preserve the three-minute budget', (
    tester,
  ) async {
    final loc = AppLocalizationsEn();
    final clock = _WidgetDecisionClock(tester.binding.clock.now);
    final harness = _XswdTestHarness(loc, clock: clock);
    final container = harness.container;
    addTearDown(container.dispose);
    final decision = harness.newRequest(
      _permissionRequest(id: 1, method: 'get_address'),
    );
    await tester.pump(const Duration(seconds: 75));
    await tester.pumpWidget(_budgetTestApp(container));
    expect(find.text(loc.xswd_expires_in('1:45')), findsOneWidget);
    expect(container.read(xswdRequestProvider).pending, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpWidget(_budgetTestApp(container));
    expect(find.text(loc.xswd_expires_in('1:30')), findsOneWidget);
    await tester.tap(find.text(loc.xswd_allow_once));
    await tester.pump(const Duration(milliseconds: 200));
    expect(await decision, XelisXswdDecision.accept);
    container.read(xswdRequestProvider.notifier).clearRequest();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'resume refreshes the deadline and expired actions cannot reach a successor',
    (tester) async {
      final loc = AppLocalizationsEn();
      final clock = _WidgetDecisionClock(tester.binding.clock.now);
      final harness = _XswdTestHarness(loc, clock: clock);
      final container = harness.container;
      addTearDown(container.dispose);
      final first = harness.newRequest(
        _permissionRequest(id: 1, method: 'get_address'),
      );
      await tester.pumpWidget(_budgetTestApp(container));
      final oldAllow = tester.widget<FButton>(
        find.widgetWithText(FButton, loc.xswd_allow_once),
      );
      _setTestPaused(tester, true);
      clock.jump(const Duration(seconds: 151));
      _setTestPaused(tester, false);
      await tester.pump();
      expect(find.text(loc.xswd_expires_in('0:29')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.liveRegion == true &&
              widget.properties.label == loc.xswd_expiring_soon,
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(loc.xswd_expires_in('0:28')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.liveRegion == true &&
              widget.properties.label == loc.xswd_expiring_soon,
        ),
        findsOneWidget,
      );
      _setTestPaused(tester, true);
      clock.jump(const Duration(seconds: 29));
      _setTestPaused(tester, false);
      await tester.pump();
      expect(await first, XelisXswdDecision.reject);
      expect(
        container.read(xswdRecentChoicesProvider).single.outcome,
        XswdChoiceOutcome.expired,
      );
      final next = harness.newRequest(
        _permissionRequest(id: 2, method: 'get_balance'),
      );
      final nextToken = container.read(xswdRequestProvider).token;
      await tester.pump();
      expect(find.text(loc.xswd_expires_in('3:00')), findsOneWidget);
      oldAllow.onPress?.call();
      await tester.pump();
      expect(container.read(xswdRequestProvider).pending, isTrue);
      expect(container.read(xswdRequestProvider).token, same(nextToken));
      container.read(xswdRequestProvider.notifier).clearRequest();
      expect(await next, XelisXswdDecision.reject);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _budgetTestApp(ProviderContainer container) {
  final theme = greenDark(touch: false);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: theme.toApproximateMaterialTheme(),
      home: GenesixTheme(
        data: theme,
        child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
      ),
    ),
  );
}

void _setTestPaused(WidgetTester tester, bool paused) {
  for (final state
      in paused
          ? [
              AppLifecycleState.inactive,
              AppLifecycleState.hidden,
              AppLifecycleState.paused,
            ]
          : [
              AppLifecycleState.hidden,
              AppLifecycleState.inactive,
              AppLifecycleState.resumed,
            ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

final class _WidgetDecisionClock implements XswdDecisionClock {
  _WidgetDecisionClock(this._now) : _start = _now();
  final DateTime Function() _now;
  final DateTime _start;
  Duration _offset = Duration.zero;
  @override
  Duration now() => _now().difference(_start) + _offset;
  void jump(Duration elapsed) => _offset += elapsed;
  @override
  XswdScheduledTask schedule(Duration delay, void Function() callback) =>
      _WidgetScheduledTask(Timer(delay, callback));
}

final class _WidgetScheduledTask implements XswdScheduledTask {
  _WidgetScheduledTask(this.timer);
  final Timer timer;
  @override
  bool get isActive => timer.isActive;
  @override
  void cancel() => timer.cancel();
}

XelisXswdRequest _permissionRequest({required int id, required String method}) {
  return XelisXswdRequest(
    kind: XelisXswdRequestKind.permission,
    application: _application,
    payload: xswdTestPayload({'id': id, 'jsonrpc': '2.0', 'method': method}),
  );
}

XelisXswdRequest _invokePermissionRequest({
  required int id,
  required Object permission,
  List<Map<String, dynamic>> parameters = const [],
}) => XelisXswdRequest(
  kind: XelisXswdRequestKind.permission,
  application: _application,
  payload: xswdTestPayload({
    'id': id,
    'jsonrpc': '2.0',
    'method': WalletMethod.buildTransaction.jsonKey,
    'params': {
      'invoke_contract': {
        'contract': _contractHash,
        'max_gas': 7,
        'entry_id': 3,
        'parameters': parameters,
        'permission': permission,
      },
    },
  }),
);

Map<String, Object> _listedPermission({
  required String outer,
  required Object chunk,
}) => {
  outer: [
    {'contract': _calledContractHash, 'chunk': chunk},
  ],
};

Future<void> _pumpXswdDialog(
  WidgetTester tester,
  ProviderContainer container, {
  double textScale = 1,
}) async {
  final theme = greenDark(touch: tester.view.physicalSize.width < 600);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
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
}

XelisXswdRequest _prefetchRequest({required List<String> permissions}) {
  return XelisXswdRequest(
    kind: XelisXswdRequestKind.prefetchPermissions,
    application: _application,
    payload: xswdTestPayload({
      'reason': 'Review wallet access',
      'permissions': permissions,
    }),
  );
}

final _application = XelisXswdApplication(
  id: 'app-id',
  name: 'Test app',
  description: 'Test application',
  url: null,
  permissions: const {},
  isRelayer: false,
);

final class _XswdTestHarness {
  factory _XswdTestHarness(AppLocalizations loc, {XswdDecisionClock? clock}) {
    final repository = _FakeNativeWalletRepository();
    return _XswdTestHarness._(
      repository,
      ProviderContainer(
        overrides: [
          if (clock != null) xswdDecisionClockProvider.overrideWithValue(clock),
          appLocalizationsProvider.overrideWithValue(loc),
          activeWalletRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
  }

  const _XswdTestHarness._(this.repository, this.container);

  final _FakeNativeWalletRepository repository;
  final ProviderContainer container;

  Future<XelisXswdDecision> newRequest(XelisXswdRequest request) {
    return container
        .read(xswdRequestProvider.notifier)
        .newRequest(
          xswdEventSummary: request,
          message: 'Review request',
          repository: repository,
        );
  }

  Future<XelisXswdPrefetchDecision> newPrefetchRequest(
    XelisXswdRequest request, {
    Map<String, XelisXswdPermissionPolicy> currentPermissions = const {},
  }) {
    return container
        .read(xswdRequestProvider.notifier)
        .newPrefetchRequest(
          preflight: XswdPrefetchPreflight.parse(request),
          message: 'Review permissions',
          repository: repository,
          currentPermissions: currentPermissions,
        );
  }
}

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  @override
  String get address => 'wallet-address';

  @override
  XelisNetwork get network => XelisNetwork.mainnet;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
