import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
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
              payloadJson: jsonEncode({
                'id': 1,
                'jsonrpc': '2.0',
                'method': WalletMethod.buildTransaction.jsonKey,
                'params': {
                  'transfers': [
                    {
                      'asset': 'asset-hash',
                      'amount': 42,
                      'destination': 'xel:destination',
                      'extra_data': 'attached-data',
                      'encrypt_extra_data': false,
                    },
                  ],
                  'fee': {'Value': 7},
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
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(viewport.textScale)),
              child: child!,
            ),
            theme: theme.toApproximateMaterialTheme(),
            home: FTheme(
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
      expect(find.text('xel:destination'), findsOneWidget);
      expect(find.text('Attached data'), findsOneWidget);
      expect(
        find.textContaining('Not encrypted', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('7 atomic units'), findsOneWidget);
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
      expect(tester.takeException(), isNull);

      container.read(xswdRequestProvider.notifier).clearRequest();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

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
            payloadJson: jsonEncode({
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
          home: FTheme(
            data: theme,
            child: const Scaffold(body: XswdDialog(kAlwaysCompleteAnimation)),
          ),
        ),
      ),
    );

    expect(find.text('get_balance').hitTestable(), findsOneWidget);
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
