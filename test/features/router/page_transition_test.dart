import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/router/routes.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('transition preserves the $brightness app canvas color', (
      tester,
    ) async {
      const canvasColor = Color(0xFF123456);
      final page = pageTransition<void>(
        const SizedBox(width: 100, height: 100),
        const ValueKey('transition'),
        '/transition',
        null,
        300,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness, canvasColor: canvasColor),
          home: Builder(
            builder: (context) => page.transitionsBuilder(
              context,
              const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0.0),
              page.child,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .map((box) => box.color),
        contains(canvasColor),
      );
    });
  }
}
