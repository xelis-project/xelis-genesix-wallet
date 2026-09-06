import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/async_f_button.dart';

void main() {
  testWidgets('routes enabled presses to the primary callback', (tester) async {
    var presses = 0;
    var disabledPresses = 0;

    await _pumpButton(
      tester,
      isLoading: false,
      onPress: () => presses++,
      onDisabledPress: () => disabledPresses++,
    );

    await tester.tap(find.byType(AsyncFButton));
    await tester.pump(const Duration(milliseconds: 250));

    expect(presses, 1);
    expect(disabledPresses, 0);
  });

  testWidgets('routes idle disabled presses to the feedback callback', (
    tester,
  ) async {
    var disabledPresses = 0;

    await _pumpButton(
      tester,
      isLoading: false,
      onPress: null,
      onDisabledPress: () => disabledPresses++,
    );

    await tester.tap(find.byType(AsyncFButton));
    await tester.pump(const Duration(milliseconds: 250));

    expect(disabledPresses, 1);
  });

  testWidgets('keeps both callbacks inert while loading', (tester) async {
    var presses = 0;
    var disabledPresses = 0;

    await _pumpButton(
      tester,
      isLoading: true,
      onPress: () => presses++,
      onDisabledPress: () => disabledPresses++,
    );

    await tester.tap(find.byType(AsyncFButton));
    await tester.pump(const Duration(milliseconds: 250));

    expect(presses, 0);
    expect(disabledPresses, 0);
  });
}

Future<void> _pumpButton(
  WidgetTester tester, {
  required bool isLoading,
  required VoidCallback? onPress,
  required VoidCallback? onDisabledPress,
}) async {
  final theme = greenDark(touch: false);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme.toApproximateMaterialTheme(),
      home: GenesixTheme(
        data: theme,
        child: Center(
          child: AsyncFButton(
            isLoading: isLoading,
            onPress: onPress,
            onDisabledPress: onDisabledPress,
            child: const Text('Continue'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
