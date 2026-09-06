import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/models/toast_content.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/shared/widgets/components/toaster_widget.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';

const _supportReference =
    'XWF-0C95-9A2D-46FE-E9A3-D309 · xelisWallet · wallet.open · '
    'wallet.authentication_or_corrupt_data';

void main() {
  testWidgets('renders the complete structured failure hierarchy', (
    tester,
  ) async {
    final harness = await _pumpToaster(tester);
    const description =
        'The password is incorrect or the wallet data cannot be read.';

    _showError(
      harness,
      description: description,
      supportReference: _supportReference,
    );
    await tester.pumpAndSettle();

    final toast = find.byKey(const ValueKey('structured-error-toast'));
    final supportText = harness.localizations.support_reference(
      _supportReference,
    );
    expect(toast, findsOneWidget);
    expect(find.text(description), findsOneWidget);
    expect(find.text(supportText), findsOneWidget);

    final message = tester.widget<Text>(find.text(description));
    final reference = tester.widget<Text>(find.text(supportText));
    final toastContext = tester.element(toast);
    expect(message.maxLines, isNull);
    expect(message.style?.fontWeight, FontWeight.w600);
    expect(message.style?.color, toastContext.theme.colors.foreground);
    expect(reference.maxLines, isNull);
    expect(reference.style?.fontWeight, FontWeight.w400);
    expect(reference.style?.color, toastContext.theme.colors.mutedForeground);
    expect(tester.getSize(toast).height, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('caps extreme structured content and keeps it scrollable', (
    tester,
  ) async {
    final harness = await _pumpToaster(
      tester,
      size: const Size(320, 480),
      textScale: 2,
    );
    final description = List.filled(
      18,
      'The wallet could not complete the requested operation safely.',
    ).join(' ');

    _showError(
      harness,
      description: description,
      supportReference: _supportReference,
    );
    await tester.pumpAndSettle();

    final toast = find.byKey(const ValueKey('structured-error-toast'));
    final scrollable = find.descendant(
      of: toast,
      matching: find.byType(Scrollable),
    );
    final dismiss = find.byKey(const ValueKey('structured-error-dismiss'));
    expect(scrollable, findsOneWidget);
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
    );
    expect(tester.getSize(toast).height, lessThanOrEqualTo(222.1));
    expect(dismiss, findsOneWidget);
    expect(tester.getRect(toast).contains(tester.getCenter(dismiss)), isTrue);
    expect(find.text(description), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copies only the raw support reference', (tester) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final semantics = tester.ensureSemantics();
    final harness = await _pumpToaster(tester);

    _showError(
      harness,
      description: 'A safe, localized message.',
      supportReference: _supportReference,
    );
    await tester.pumpAndSettle();

    final copyButton = find.byKey(const ValueKey('support-reference-copy'));
    final visibleReference = harness.localizations.support_reference(
      _supportReference,
    );
    final semanticButton = find.byKey(
      const ValueKey('support-reference-semantics'),
    );
    expect(semanticButton, findsOneWidget);
    final semanticsData = tester
        .getSemantics(semanticButton)
        .getSemanticsData();
    expect(semanticsData.label, visibleReference);
    expect(semanticsData.hint, harness.localizations.copy);
    expect(semanticsData.flagsCollection.isButton, isTrue);
    expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(copyButton);
    await tester.pump(const Duration(milliseconds: 200));

    expect(clipboardText, _supportReference);
    expect(clipboardText, isNot(contains('Support reference:')));
    expect(
      find.descendant(
        of: copyButton,
        matching: find.byIcon(FLucideIcons.check),
      ),
      findsOneWidget,
    );
    semantics.dispose();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('centers the copy icon against a wrapped support reference', (
    tester,
  ) async {
    final harness = await _pumpToaster(tester, size: const Size(320, 480));

    _showError(
      harness,
      description: 'A safe, localized message.',
      supportReference: _supportReference,
    );
    await tester.pumpAndSettle();

    final copyButton = find.byKey(const ValueKey('support-reference-copy'));
    final visibleReference = harness.localizations.support_reference(
      _supportReference,
    );
    final reference = find.text(visibleReference);
    final copyIcon = find.descendant(
      of: copyButton,
      matching: find.byIcon(FLucideIcons.copy),
    );

    expect(reference, findsOneWidget);
    expect(copyIcon, findsOneWidget);
    expect(tester.getSize(reference).height, greaterThan(20));
    expect(
      (tester.getCenter(copyIcon).dy - tester.getCenter(reference).dy).abs(),
      lessThan(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps legacy raw errors bounded pending their migration', (
    tester,
  ) async {
    final harness = await _pumpToaster(tester, size: const Size(320, 480));
    final description = List.filled(
      10,
      'Legacy native diagnostic that is not support-safe.',
    ).join(' ');

    _showError(harness, description: description);
    await tester.pumpAndSettle();

    final toast = find.byType(FToast);
    final message = tester.widget<Text>(find.text(description));
    expect(message.maxLines, 2);
    expect(message.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(toast).height, lessThanOrEqualTo(220));
    expect(tester.takeException(), isNull);
  });
}

class _ToastHarness {
  const _ToastHarness({required this.container, required this.localizations});

  final ProviderContainer container;
  final AppLocalizationsEn localizations;
}

Future<_ToastHarness> _pumpToaster(
  WidgetTester tester, {
  Size size = const Size(420, 700),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final localizations = AppLocalizationsEn();
  final container = ProviderContainer(
    overrides: [appLocalizationsProvider.overrideWithValue(localizations)],
  );
  addTearDown(container.dispose);
  final theme = greenDark(touch: false);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.toApproximateMaterialTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: GenesixTheme(
          data: theme,
          child: const ToasterWidget(child: SizedBox.expand()),
        ),
      ),
    ),
  );
  await tester.pump();

  return _ToastHarness(container: container, localizations: localizations);
}

void _showError(
  _ToastHarness harness, {
  required String description,
  String? supportReference,
}) {
  harness.container
      .read(toastProvider.notifier)
      .show(
        ToastContent.error(
          title: 'Wallet error',
          description: description,
          supportReference: supportReference,
          sticky: supportReference != null,
        ),
      );
}
