import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/address_book/contact_list_tile.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets('exposes the open action and activates the contact row', (
    tester,
  ) async {
    var openCount = 0;

    await _pumpTile(tester, onOpen: () => openCount++);

    final identity = find.descendant(
      of: find.byType(ContactListTile),
      matching: find.byType(FItem),
    );
    final item = tester.widget<FItem>(identity);
    expect(item.semanticsLabel, isNull);
    expect(item.semanticsTooltip, 'Open');
    expect(item.onPress, isNotNull);

    await tester.tap(identity);
    await tester.pumpAndSettle();

    expect(openCount, 1);
  });

  testWidgets('keeps nested contact actions independent from the open action', (
    tester,
  ) async {
    var openCount = 0;
    var sendCount = 0;

    await _pumpTile(
      tester,
      onOpen: () => openCount++,
      onSend: () => sendCount++,
    );

    final send = find.byIcon(FLucideIcons.send);
    final sendButton = find.ancestor(of: send, matching: find.byType(FButton));
    expect(tester.widget<FButton>(sendButton).semanticsTooltip, isNotEmpty);

    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(sendCount, 1);
    expect(openCount, 0);
  });

  testWidgets('does not expose a button when the contact is not openable', (
    tester,
  ) async {
    await _pumpTile(tester);

    final identity = find.descendant(
      of: find.byType(ContactListTile),
      matching: find.byType(FItem),
    );
    final item = tester.widget<FItem>(identity);
    expect(item.onPress, isNull);
    expect(item.semanticsLabel, isNull);
    expect(item.semanticsTooltip, isNull);
  });
}

Future<void> _pumpTile(
  WidgetTester tester, {
  VoidCallback? onOpen,
  VoidCallback? onSend,
}) async {
  final theme = greenDark(touch: false);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.toApproximateMaterialTheme(),
      home: FTheme(
        data: theme,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 600,
              child: FItemGroup.builder(
                count: 1,
                itemBuilder: (context, index) => ContactListTile(
                  contact: _contact,
                  localizations: AppLocalizationsEn(),
                  onOpen: onOpen,
                  onSend: onSend,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _contact = XelisAddressBookEntry(
  id: 'entry-a',
  displayName: 'Exchange A',
  destination: XelisSavedDestination(
    address: 'xel:exchange-a',
    baseAddress: 'xel:exchange-a',
    kind: XelisSavedDestinationKind.standard,
    integratedDataKind: null,
  ),
);
