import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_full_value_view.dart';
import 'package:genesix/features/wallet/presentation/xswd/components/xswd_json_parameters_view.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart';

void main() {
  test('preview visits a fixed prefix of a near-budget parameter tree', () {
    final parameters = <String, dynamic>{
      'values': List<dynamic>.filled(299990, null),
    };

    final preview = xswdJsonPreview(parameters);

    expect(preview.isTruncated, isTrue);
    expect(preview.visitedNodes, 5);
    expect(preview.text.length, lessThanOrEqualTo(512));
  });

  test('preview never invokes an unsupported value toString', () {
    final preview = xswdJsonPreview({'secret': _ToStringTrap()});

    expect(preview.text, contains('<unsupported>'));
    expect(preview.isTruncated, isTrue);
  });

  test('small previews preserve exact wide integers and Unicode', () {
    final preview = xswdJsonPreview({
      'wide': BigInt.parse('9007199254740993'),
      'note': 'précis 😀',
    });

    expect(preview.isTruncated, isFalse);
    expect(preview.text, contains('9007199254740993'));
    expect(preview.text, contains('précis 😀'));
  });

  for (final width in [320.0, 800.0]) {
    testWidgets('large parameters reveal exact segmented JSON at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final tail = 'fin-précise-😀';
      final parameters = <String, dynamic>{
        'wide': BigInt.parse('18446744073709551615'),
        'note': '${'a' * 200000}$tail',
        'values': List<int>.generate(4090, (index) => index),
      };

      await _pump(tester, parameters);

      final preview = tester.widget<SelectableText>(
        find.byKey(const ValueKey('xswd-json-parameters-preview')),
      );
      expect(preview.data!.length, lessThanOrEqualTo(512));
      expect(preview.data, isNot(contains(tail)));
      expect(find.byType(XswdFullValueView), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('xswd-json-parameters-reveal')),
      );
      await tester.pump(const Duration(milliseconds: 150));

      final full = tester.widget<XswdFullValueView>(
        find.byKey(const ValueKey('xswd-json-parameters-full')),
      );
      expect(full.value, serializeBigIntJson(parameters, indent: '  '));
      expect(full.value, contains('18446744073709551615'));
      expect(full.value, contains(tail));
      expect(
        find.byKey(const ValueKey('xswd-json-parameters-full-list')),
        findsOneWidget,
      );
      expect(find.byType(SelectableText).evaluate().length, lessThan(20));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
    });
  }
}

Future<void> _pump(WidgetTester tester, Map<String, dynamic> parameters) async {
  final theme = greenDark(touch: false);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.toApproximateMaterialTheme(),
      home: FTheme(
        data: theme,
        child: Scaffold(
          body: SingleChildScrollView(
            child: XswdJsonParametersView(
              parameters: parameters,
              loc: AppLocalizationsEn(),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _ToStringTrap {
  @override
  String toString() => throw StateError('Sensitive value was stringified.');
}
