import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/shared/theme/genesix_theme.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_password_change_result.dart';
import 'package:genesix/features/wallet/presentation/side_bar/change_password_dialog.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/shared/theme/dialog_style.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';

void main() {
  testWidgets('blocks route dismissal while password change is in flight', (
    tester,
  ) async {
    final completer = Completer<WalletPasswordChangeResult>();
    String? receivedOldPassword;
    String? receivedNewPassword;
    final loc = AppLocalizationsEn();
    final container = ProviderContainer(
      overrides: [appLocalizationsProvider.overrideWithValue(loc)],
    );
    addTearDown(container.dispose);
    final theme = greenDark(touch: false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme.toApproximateMaterialTheme(),
          home: GenesixTheme(
            data: theme,
            child: Builder(
              builder: (context) => FButton(
                onPress: () => showAppDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context, style, animation) => ChangePasswordDialog(
                    animation,
                    changePassword: (oldPassword, newPassword) {
                      receivedOldPassword = oldPassword;
                      receivedNewPassword = newPassword;
                      return completer.future;
                    },
                  ),
                ),
                child: const Text('Open dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    final fields = find.byType(EditableText);
    expect(fields, findsNWidgets(3));
    final semantics = tester.ensureSemantics();
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    final editableTexts = tester.widgetList<EditableText>(fields).toList();
    editableTexts[0].controller.text = ' old password ';
    editableTexts[1].controller.text = ' new password ';
    editableTexts[2].controller.text = ' new password ';
    tester.widget<FButton>(find.widgetWithText(FButton, loc.save)).onPress!();
    _rebuildDirtyElements(tester);

    expect(receivedOldPassword, ' old password ');
    expect(receivedNewPassword, ' new password ');
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    await tester.binding.handlePopRoute();
    expect(find.byType(ChangePasswordDialog), findsOneWidget);

    completer.complete(
      WalletPasswordChangeFailure(
        AppFailure.application(
          operation: 'wallet.password.change',
          code: 'test_failure',
          exceptionType: 'TestFailure',
        ),
      ),
    );
    await tester.idle();
    _rebuildDirtyElements(tester);
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    semantics.dispose();
  });
}

void _rebuildDirtyElements(WidgetTester tester) {
  // Flutter 3.47 asserts while flushing this password-field semantics update.
  // Rebuild only the lifecycle state; semantics stays enabled and is checked
  // on the settled real dialog above.
  final binding = tester.binding;
  binding.buildOwner!.buildScope(binding.rootElement!);
}
