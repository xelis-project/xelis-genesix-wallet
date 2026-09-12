import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/xswd_lifecycle_provider.dart';
import 'package:genesix/features/wallet/application/xswd_notification_service.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/xswd_lifecycle_state.dart';
import 'package:genesix/shared/widgets/genesix_app.dart';
import 'package:genesix/shared/errors/app_failure_reporter.dart';
import 'package:genesix/src/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  testWidgets(
    'saved language overrides Windows for screens and a visible XSWD toast',
    (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('fr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final repository = _Repository();
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const _LocaleProbe()),
        ],
      );
      addTearDown(router.dispose);
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(_TestSettings.new),
          routerProvider.overrideWithValue(router),
          xswdLifecycleProvider.overrideWithValue(const XswdLifecycleState()),
          xswdNotificationServiceProvider.overrideWithValue(_Notifications()),
          activeWalletRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const Genesix()),
      );
      await tester.pumpAndSettle();
      final decision = container
          .read(xswdRequestProvider.notifier)
          .newRequest(
            xswdEventSummary: XelisXswdRequest(
              kind: XelisXswdRequestKind.application,
              application: XelisXswdApplication(
                id: 'test',
                name: 'Example dApp',
                description: '',
                url: null,
                permissions: const {},
                isRelayer: false,
              ),
            ),
            message: '',
            repository: repository,
          );
      final token = container.read(xswdRequestProvider).token!;
      await tester.pumpAndSettle();
      expect(find.text('context=en provider=en'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Deny'), findsOneWidget);
      expect(find.text('Connection request'), findsOneWidget);
      expect(find.text('Ouvrir'), findsNothing);

      container.read(settingsProvider.notifier).setLocale(const Locale('fr'));
      await tester.pumpAndSettle();
      expect(find.text('context=fr provider=fr'), findsOneWidget);
      expect(find.text('Ouvrir'), findsOneWidget);
      expect(find.text('Refuser'), findsOneWidget);
      expect(find.text('Requête de connexion'), findsOneWidget);
      expect(container.read(xswdRequestProvider).token, same(token));
      expect(container.read(xswdRequestProvider).pending, isTrue);
      container.read(xswdRequestProvider.notifier).rejectIfCurrent(token);
      expect(await decision, XelisXswdDecision.reject);
      final loc = container.read(appLocalizationsProvider);
      final failure = recordAppFailure(
        const FormatException('SENSITIVE_PARAMETER'),
        StackTrace.empty,
        operation: 'xswd.request.parse',
        applicationCode: 'xswd_request_invalid',
      );
      container
          .read(walletEffectBusProvider.notifier)
          .emit(
            WalletEffect.failure(
              title: loc.prefetch_permissions_request,
              description: loc.xswd_permission_request_rejected,
              failure: failure,
            ),
          );
      await tester.pumpAndSettle();
      expect(find.text(loc.xswd_permission_request_rejected), findsOneWidget);
      expect(find.textContaining(failure.supportReference), findsOneWidget);
      expect(find.textContaining('SENSITIVE_PARAMETER'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

class _LocaleProbe extends ConsumerWidget {
  const _LocaleProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Text(
    'context=${AppLocalizations.of(context).localeName} provider=${ref.watch(appLocalizationsProvider).localeName}',
  );
}

class _TestSettings extends Settings {
  @override
  SettingsState build() => const SettingsState(locale: Locale('en'));

  @override
  void setLocale(Locale locale) => state = state.copyWith(locale: locale);
}

class _Repository implements NativeWalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifications extends XswdNotificationService {
  _Notifications() : super(onApprovalOpen: () {});

  @override
  Future<void> initialize() async {}
}
