import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/resources/localizations.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
// A deliberate legacy consumer verifies compatibility for third-party widgets.
import 'package:flutter/material.dart' as legacy;

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'both Material libraries share the ${dark ? 'dark' : 'light'} theme and French locale',
      (tester) async {
        final theme = dark ? greenDark(touch: true) : greenLight(touch: true);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: genesixLocalizationsDelegates,
            theme: theme.toApproximateMaterialTheme(),
            home: GenesixTheme(
              data: theme,
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    expect(
                      Theme.of(context).colorScheme.surface,
                      theme.colors.background,
                    );
                    expect(
                      legacy.Theme.of(context).colorScheme.surface,
                      theme.colors.background,
                    );
                    // The upstream bridge merges legacy typography defaults;
                    // compare the font properties explicitly owned by Forui.
                    final modernText = Theme.of(context).textTheme.bodyMedium!;
                    final legacyText = legacy.Theme.of(context)
                        .textTheme
                        .bodyMedium!;
                    expect(legacyText.color, modernText.color);
                    expect(legacyText.fontFamily, modernText.fontFamily);
                    expect(legacyText.fontSize, modernText.fontSize);
                    expect(legacyText.height, modernText.height);
                    expect(
                      legacy.MaterialLocalizations.of(context).pasteButtonLabel,
                      MaterialLocalizations.of(context).pasteButtonLabel,
                    );
                    expect(FLocalizations.of(context)!.localeName, 'fr');
                    return const Column(
                      children: [
                        TextField(key: ValueKey('material')),
                        FTextField(key: ValueKey('forui')),
                        SelectableText('support reference'),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final field = find.descendant(
          of: find.byKey(const ValueKey('forui')),
          matching: find.byType(EditableText),
        );
        await tester.enterText(field, 'before');
        final editable = tester.state<EditableTextState>(field);
        editable.widget.controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 6,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => switch (call.method) {
            'Clipboard.getData' => {'text': 'texte collé'},
            'Clipboard.hasStrings' => {'value': true},
            _ => null,
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await editable.pasteText(SelectionChangedCause.keyboard);
        await tester.pump();
        expect(editable.widget.controller.text, 'texte collé');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
