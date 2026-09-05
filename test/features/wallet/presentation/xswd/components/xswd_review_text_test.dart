import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_review_text.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';

void main() {
  for (final width in [320.0, 800.0]) {
    testWidgets('large reason is bounded and revealed exactly at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final value = '${'a' * 255}😀${'b' * (2 * 1024 * 1024 - 261)}tail';
      await _pump(tester, value);
      final preview = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('xswd-review-text-preview')),
          )
          .data!;
      expect(preview, '${'a' * 255}…');
      expect(preview, isNot(contains('tail')));
      expect(find.byType(XswdFullValueView), findsNothing);
      await tester.tap(find.byKey(const ValueKey('xswd-review-text-reveal')));
      await tester.pump(const Duration(milliseconds: 150));
      final full = tester.widget<XswdFullValueView>(
        find.byType(XswdFullValueView),
      );
      expect(full.value, value);
      expect(find.byType(SelectableText).evaluate().length, lessThan(20));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
    });
  }

  testWidgets('short reason needs no reveal', (tester) async {
    await _pump(tester, 'Read wallet data');
    expect(find.text('Read wallet data'), findsOneWidget);
    expect(find.byKey(const ValueKey('xswd-review-text-reveal')), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, String value) async {
  final theme = greenDark(touch: false);
  final loc = AppLocalizationsEn();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.toApproximateMaterialTheme(),
      home: FTheme(
        data: theme,
        child: Scaffold(
          body: SingleChildScrollView(
            child: XswdReviewText(label: loc.reason, value: value, loc: loc),
          ),
        ),
      ),
    ),
  );
}
