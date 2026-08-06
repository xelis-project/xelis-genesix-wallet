import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_password_change_result.dart';
import 'package:genesix/features/wallet/presentation/side_bar/change_password_dialog.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/shared/theme/theme.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';

void main() {
  testWidgets('blocks route dismissal while password change is in flight', (
    tester,
  ) async {
    final completer = Completer<WalletPasswordChangeResult>();
    String? receivedOldPassword;
    String? receivedNewPassword;
    final container = ProviderContainer(
      overrides: [
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      ],
    );
    addTearDown(container.dispose);
    final theme = greenDark(touch: false);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme.toApproximateMaterialTheme(),
          home: FTheme(
            data: theme,
            child: ChangePasswordDialog(
              const AlwaysStoppedAnimation(1),
              changePassword: (oldPassword, newPassword) {
                receivedOldPassword = oldPassword;
                receivedNewPassword = newPassword;
                return completer.future;
              },
            ),
          ),
        ),
      ),
    );

    final fields = find.byType(EditableText);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), ' old password ');
    await tester.enterText(fields.at(1), ' new password ');
    await tester.enterText(fields.at(2), ' new password ');
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 150));

    expect(receivedOldPassword, ' old password ');
    expect(receivedNewPassword, ' new password ');
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();
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
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
  });
}
