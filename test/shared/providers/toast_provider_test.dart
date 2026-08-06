import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/shared/models/app_failure.dart';
import 'package:genesix/shared/models/toast_content.dart';
import 'package:genesix/shared/providers/toast_provider.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  late ProviderContainer container;
  late AppLocalizationsEn localizations;

  setUp(() {
    localizations = AppLocalizationsEn();
    container = ProviderContainer(
      overrides: [appLocalizationsProvider.overrideWithValue(localizations)],
    );
  });

  tearDown(() => container.dispose());

  test('showFailure creates a sticky error with a support reference', () {
    final failure = AppFailure.fromXelis(
      XelisWalletOperationException(
        source: XelisWalletErrorSource.xelisWallet,
        operation: XelisWalletOperation.configurationInitialize,
        code: XelisWalletErrorCode.networkFailure,
        supportId: 'XWF-1234-ABCD-5678-EF90-1234',
        diagnosticMessage: 'must never reach the toast',
      ),
    );

    container.read(toastProvider.notifier).showFailure(failure: failure);

    final toast = container.read(toastProvider) as ErrorToastContent;
    expect(toast.title, localizations.error);
    expect(toast.description, localizations.wallet_failure_network);
    expect(toast.supportReference, failure.supportReference);
    expect(toast.sticky, isTrue);
    expect(toast.dismissible, isTrue);
    expect(toast.supportReference, isNot(contains('must never reach')));
  });

  test('legacy showError remains non-sticky and has no support reference', () {
    container
        .read(toastProvider.notifier)
        .showError(description: 'Expected local validation error');

    final toast = container.read(toastProvider) as ErrorToastContent;
    expect(toast.description, 'Expected local validation error');
    expect(toast.supportReference, isNull);
    expect(toast.sticky, isFalse);
  });

  test('showFailure accepts reviewed localized copy for partial outcomes', () {
    final failure = AppFailure.application(
      operation: 'wallet.password.biometric.persist',
      code: 'wallet_password_biometric_persist_failed',
      exceptionType: 'PlatformException',
      category: AppFailureCategory.storageFailure,
    );

    container
        .read(toastProvider.notifier)
        .showFailure(
          title: localizations.change_password,
          description: localizations.password_changed_biometric_disabled,
          failure: failure,
        );

    final toast = container.read(toastProvider) as ErrorToastContent;
    expect(toast.title, localizations.change_password);
    expect(
      toast.description,
      localizations.password_changed_biometric_disabled,
    );
    expect(toast.supportReference, failure.supportReference);
    expect(toast.sticky, isTrue);
  });
}
