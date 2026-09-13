import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/settings/application/app_localizations_provider.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/settings/domain/settings_state.dart';
import 'package:genesix/features/wallet/application/wallet_effect_bus_provider.dart';
import 'package:genesix/features/wallet/application/wallet_runtime_provider.dart';
import 'package:genesix/features/wallet/application/xswd_controller_provider.dart';
import 'package:genesix/features/wallet/application/xswd_diagnostics.dart';
import 'package:genesix/features/wallet/application/xswd_decision_timing.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/xswd_lifecycle_provider.dart';
import 'package:genesix/features/wallet/application/xswd_notification_service.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/wallet_effect.dart';
import 'package:genesix/features/wallet/domain/wallet_runtime_state.dart';
import 'package:genesix/features/wallet/domain/xswd_lifecycle_state.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/src/generated/l10n/app_localizations_en.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart'
    show BurnBuilder, FixedFeeBuilder, parseBigIntJson;

import '../../../helpers/xswd_test_payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('callbacks use separate safety budgets and preflight expiry preserves another approval', () async {
    final repository = _FakeNativeWalletRepository('a');
    final clock = _FakeXswdDecisionClock();
    final container = _connectedXswdContainer(repository, clock: clock);
    addTearDown(container.dispose);
    await container.read(xswdControllerProvider).startXSWD(repository);
    final callbacks = repository.callbacks!;
    expect(callbacks.decisionTimeout, xswdDecisionSafetyTimeout);
    expect(callbacks.notificationTimeout, xswdNotificationTimeout);

    final otherApplication = XelisXswdApplication(
      id: 'other-app',
      name: 'Other example app',
      description: '',
      url: null,
      permissions: const {},
      isRelayer: true,
    );
    final otherDecision = container
        .read(xswdRequestProvider.notifier)
        .newRequest(
          xswdEventSummary: XelisXswdRequest(
            kind: XelisXswdRequestKind.application,
            application: otherApplication,
          ),
          message: '',
          repository: repository,
          decisionDeadline: const Duration(minutes: 10),
        );
    final preserved = container.read(xswdRequestProvider);

    repository.xswdApplications = [_application];
    final gate = Completer<void>();
    repository.stateReadGate = gate;
    final prefetch = callbacks.onPrefetchPermissionsReview!(
      XelisXswdRequest(
        kind: XelisXswdRequestKind.prefetchPermissions,
        application: _application,
        payload: xswdTestPayload({
          'permissions': ['get_balance', 'build_transaction'],
        }),
      ).prefetchPermissionsRequest!,
    );

    clock.advance(xswdUserDecisionBudget);
    expect(await prefetch, isA<XelisXswdPrefetchNoChange>());
    expect(container.read(xswdRequestProvider), same(preserved));
    expect(container.read(xswdRequestProvider).pending, isTrue);
    expect(
      container.read(xswdRecentChoicesProvider).single.outcome,
      XswdChoiceOutcome.expired,
    );

    gate.complete();
    repository.stateReadGate = null;
    container
        .read(xswdRequestProvider.notifier)
        .rejectIfCurrent(preserved.token!);
    expect(await otherDecision, XelisXswdDecision.reject);
  });

  test(
    'observation timeout refreshes cached rules without assuming success',
    () async {
      final repository = _FakeNativeWalletRepository('a');
      final container = _connectedXswdContainer(repository);
      addTearDown(container.dispose);
      await container.read(xswdControllerProvider).startXSWD(repository);
      final subscription = container.listen(
        xswdApplicationsProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      expect(await container.read(xswdApplicationsProvider.future), isEmpty);

      repository.xswdApplications = [_application];
      final timeout = XelisXswdApplicationStateTimedOut(_application, 1);
      repository.callbacks!.onApplicationStateObservation!(timeout);

      expect(await container.read(xswdApplicationsProvider.future), [
        _application,
      ]);
      expect(
        container.read(
          xswdApplicationObservationsProvider,
        )[_application.sessionReference],
        same(timeout),
      );
    },
  );

  test(
    'failed normalization closes only its origin session and prevents startup',
    () async {
      final repository = _FakeNativeWalletRepository('a');
      final application = XelisXswdApplication(
        id: 'legacy',
        name: 'Orbit Workshop',
        description: '',
        url: null,
        permissions: const {
          'sign_data': XelisXswdPermissionPolicy.accept,
          'build_transaction': XelisXswdPermissionPolicy.accept,
          'get_balance': XelisXswdPermissionPolicy.accept,
        },
        isRelayer: false,
      );
      repository.xswdApplications = [application, _application];
      repository.permissionUpdateErrorAt = 2;
      final container = _connectedXswdContainer(repository);
      addTearDown(container.dispose);
      expect(
        await container.read(xswdControllerProvider).startXSWD(repository),
        isFalse,
      );
      expect(repository.callbacks, isNull);
      expect(repository.permissionUpdates, [
        {'sign_data': XelisXswdPermissionPolicy.ask},
        {'build_transaction': XelisXswdPermissionPolicy.ask},
      ]);
      expect(repository.removedApplications, [application.sessionReference]);
    },
  );

  for (final event in ['cancel', 'disconnect', 'wallet', 'dispose']) {
    test(
      'a $event during prefetch state read cannot install a stale approval',
      () async {
        final repository = _FakeNativeWalletRepository('a');
        final clock = _FakeXswdDecisionClock();
        final container = _connectedXswdContainer(repository, clock: clock);
        if (event != 'dispose') addTearDown(container.dispose);
        await container.read(xswdControllerProvider).startXSWD(repository);
        repository.xswdApplications = [_application];
        final gate = Completer<void>();
        repository.stateReadGate = gate;
        if (event == 'cancel' || event == 'dispose') {
          repository.stateReadError = StateError('Cancelled read failed');
        }
        final effects = <WalletEffect>[];
        container.listen(walletEffectBusProvider, (_, next) {
          if (next != null) effects.add(next.effect);
        });
        final request = XelisXswdRequest(
          kind: XelisXswdRequestKind.prefetchPermissions,
          application: _application,
          payload: xswdTestPayload({
            'permissions': ['get_balance', 'build_transaction'],
          }),
        );
        final callbacks = repository.callbacks!;
        final result = callbacks.onPrefetchPermissionsReview!(
          request.prefetchPermissionsRequest!,
        );
        if (event == 'dispose') {
          container.dispose();
        } else if (event == 'wallet') {
          container
              .read(activeWalletSessionProvider.notifier)
              .setSession(
                WalletSession(
                  name: 'b',
                  repository: _FakeNativeWalletRepository('b'),
                ),
              );
        } else {
          final lifecycle = XelisXswdRequest(
            kind: event == 'cancel'
                ? XelisXswdRequestKind.cancel
                : XelisXswdRequestKind.applicationDisconnect,
            application: _application,
          );
          if (event == 'cancel') {
            await callbacks.onCancelRequest(lifecycle);
          } else {
            await callbacks.onApplicationDisconnect(lifecycle);
          }
        }
        expect(await result, isA<XelisXswdPrefetchNoChange>());
        expect(clock._tasks.any((task) => task.isActive), isFalse);
        gate.complete();
        await Future<void>.delayed(Duration.zero);
        if (event != 'dispose') {
          expect(container.read(xswdRequestProvider).pending, isFalse);
          expect(container.read(xswdRequestProvider).token, isNull);
        }
        expect(repository.permissionUpdates, isEmpty);
        expect(effects.whereType<WalletFailureEffect>(), isEmpty);
      },
    );
  }

  test('permission edits target one method and discard completion from an old wallet', () async {
    final repository = _FakeNativeWalletRepository('a');
    final container = _connectedXswdContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(xswdControllerProvider);
    final application = XelisXswdApplication(
      id: 'orbit',
      name: 'Orbit Workshop',
      description: '',
      url: null,
      permissions: const {
        'get_balance': XelisXswdPermissionPolicy.reject,
        'subscribe': XelisXswdPermissionPolicy.accept,
      },
      isRelayer: false,
    );
    expect(
      await controller.editXswdAppPermission(
        application,
        'build_transaction',
        XelisXswdPermissionPolicy.accept,
      ),
      isFalse,
    );
    expect(repository.permissionUpdates, isEmpty);
    expect(
      await controller.editXswdAppPermission(
        application,
        'get_balance',
        XelisXswdPermissionPolicy.reject,
      ),
      isTrue,
    );
    expect(repository.permissionUpdates, [
      {'get_balance': XelisXswdPermissionPolicy.reject},
    ]);
    final gate = Completer<void>();
    repository.permissionUpdateGate = gate;
    final pending = controller.editXswdAppPermission(
      application,
      'get_balance',
      XelisXswdPermissionPolicy.reject,
    );
    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'replacement', repository: repository));
    gate.complete();
    expect(await pending, isFalse);
    expect(
      application.permissions['subscribe'],
      XelisXswdPermissionPolicy.accept,
    );
  });

  for (final outcome in [
    'accept',
    'alwaysAccept',
    'reject',
    'cancel',
    'replace',
    'close',
    'close-replace',
    'close-other',
  ]) {
    test('typed request stays bound through $outcome', () async {
      final repository = _FakeNativeWalletRepository('a');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repository));
      expect(
        await container.read(xswdControllerProvider).startXSWD(repository),
        isTrue,
      );
      final request = XelisXswdRequest(
        kind: XelisXswdRequestKind.permission,
        application: _application,
        payload: xswdTestPayload(
          parseBigIntJson(
            '{"id":18446744073709551615,"jsonrpc":"2.0",'
            '"method":"build_transaction","params":{'
            '"burn":{"asset":"asset-hash","amount":9007199254740993},'
            '"nonce":18446744073709551615,"fee":{"fixed":9007199254740993}}}',
          ),
        ),
      );
      final callbacks = repository.callbacks!;
      final result = Future<XelisXswdDecision>.value(
        callbacks.onPermissionRequest(request),
      );
      final state = container.read(xswdRequestProvider);
      expect(identical(state.xswdEventSummary, request), isTrue);
      expect(
        state.permissionReview!.buildTransactionParams!.nonce,
        (BigInt.one << 64) - BigInt.one,
      );
      final reviewed = state.permissionReview!.buildTransactionParams!;
      expect(
        (reviewed.transactionTypeBuilder as BurnBuilder).amount,
        BigInt.parse('9007199254740993'),
      );
      expect(
        (reviewed.fee as FixedFeeBuilder).amount,
        BigInt.parse('9007199254740993'),
      );
      expect(container.read(xswdRequestProvider).pending, isTrue);

      if (outcome == 'close' || outcome == 'close-replace') {
        final closeGate = Completer<void>();
        repository.removeGate = closeGate;
        final close = container
            .read(xswdControllerProvider)
            .closeXswdAppConnection(_application);
        expect(container.read(xswdRequestProvider).pending, isFalse);
        expect(await result, XelisXswdDecision.reject);
        expect(container.read(xswdRequestProvider).token, isNull);
        expect(repository.removedApplications, [_application.sessionReference]);
        // A late callback from the closing transport cannot reopen consent.
        expect(
          await callbacks.onPermissionRequest(request),
          XelisXswdDecision.reject,
        );
        expect(container.read(xswdRequestProvider).token, isNull);
        final effects = <WalletEffectEnvelope?>[];
        final subscription = container.listen(
          walletEffectBusProvider,
          (_, next) => effects.add(next),
        );
        addTearDown(subscription.close);
        if (outcome == 'close-replace') {
          container
              .read(activeWalletSessionProvider.notifier)
              .setSession(
                WalletSession(
                  name: 'b',
                  repository: _FakeNativeWalletRepository('b'),
                ),
              );
        }
        closeGate.complete();
        await close;
        if (outcome == 'close-replace') expect(effects, isEmpty);
      } else if (outcome == 'close-other') {
        await container
            .read(xswdControllerProvider)
            .closeXswdAppConnection(
              XelisXswdApplication(
                id: _application.id,
                name: 'Other app',
                description: '',
                url: null,
                permissions: const {},
                isRelayer: false,
              ),
            );
        expect(container.read(xswdRequestProvider).pending, isTrue);
        expect(
          identical(container.read(xswdRequestProvider).token, state.token),
          isTrue,
        );
        container
            .read(xswdRequestProvider.notifier)
            .resolveIfCurrent(state.token!, XelisXswdDecision.accept);
      } else if (outcome == 'cancel') {
        await callbacks.onCancelRequest(
          XelisXswdRequest(
            kind: XelisXswdRequestKind.cancel,
            application: _application,
          ),
        );
      } else {
        if (outcome == 'replace') {
          container
              .read(activeWalletSessionProvider.notifier)
              .setSession(
                WalletSession(
                  name: 'b',
                  repository: _FakeNativeWalletRepository('b'),
                ),
              );
        }
        container.read(xswdRequestProvider.notifier).resolveIfCurrent(
          state.token!,
          switch (outcome) {
            'reject' => XelisXswdDecision.reject,
            'alwaysAccept' => XelisXswdDecision.alwaysAccept,
            _ => XelisXswdDecision.accept,
          },
        );
      }
      expect(await result, switch (outcome) {
        'accept' || 'alwaysAccept' || 'close-other' => XelisXswdDecision.accept,
        _ => XelisXswdDecision.reject,
      });
      container.read(xswdRequestProvider.notifier).clearRequest();
    });
  }

  // Classification variants belong to xswd_diagnostics_test.dart. Exercise
  // only the successful and refused controller paths here.
  for (final method in ['get_balance', 'future_method']) {
    test(
      'actual prefetch validation is logged separately for $method',
      () async {
        final repository = _FakeNativeWalletRepository('a');
        final container = ProviderContainer(
          overrides: [
            appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
            settingsProvider.overrideWithValue(
              const SettingsState(locale: Locale('en'), enableXswd: true),
            ),
            walletRuntimeProvider.overrideWithValue(_connectedRuntime),
            xswdNotificationServiceProvider.overrideWithValue(
              _FakeXswdNotificationService(),
            ),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(activeWalletSessionProvider.notifier)
            .setSession(WalletSession(name: 'a', repository: repository));
        await container.read(xswdControllerProvider).startXSWD(repository);
        repository.xswdApplications = [_application];
        final start = talker.history.length;
        final result = Future<XelisXswdPrefetchDecision>.value(
          repository.callbacks!.onPrefetchPermissionsReview!(
            XelisXswdRequest(
              kind: XelisXswdRequestKind.prefetchPermissions,
              application: _application,
              payload: xswdTestPayload({
                'permissions': [method],
                'reason': 'SENSITIVE_REASON',
                'params': {'private_key': 'SENSITIVE_KEY'},
              }),
            ).prefetchPermissionsRequest!,
          ),
        );
        if (method == 'get_balance') {
          await Future<void>.delayed(Duration.zero);
          final token = container.read(xswdRequestProvider).token!;
          container.read(xswdRequestProvider.notifier).resolvePrefetchIfCurrent(
            token,
            [method],
          );
        }
        expect(
          await result,
          method == 'get_balance'
              ? isA<XelisXswdPrefetchGrant>()
              : isA<XelisXswdPrefetchNoChange>(),
        );
        final entries = talker.history.skip(start).toList();
        final diagnosticEntries = entries
            .where((entry) => entry.key == xswdDiagnosticLogKey)
            .toList();
        if (diagnosticLoggingEnabled) {
          expect(diagnosticEntries, hasLength(3));
          final records = diagnosticEntries
              .map(
                (entry) => jsonDecode(entry.message!) as Map<String, dynamic>,
              )
              .toList();
          expect(records.map((record) => record['event']), [
            'received',
            'validation',
            'decision',
          ]);
          expect(
            records.map((record) => record['request']).toSet(),
            hasLength(1),
          );
          expect(
            records[1]['validation'],
            method == 'get_balance' ? 'passed' : 'failed',
          );
          expect(
            records[2]['decision'],
            method == 'get_balance' ? 'accept' : 'reject',
          );
          if (method != 'get_balance') {
            final failure =
                (container.read(walletEffectBusProvider)!.effect
                        as WalletFailureEffect)
                    .failure;
            expect(failure.operation, 'xswd.request.parse');
            expect(failure.code, 'xswd_request_invalid');
            final support = entries.singleWhere(
              (entry) => entry.key == supportLogKey,
            );
            expect(support.message, contains(failure.supportId));
            expect(
              support.message,
              contains('xswdRequest=${records.first['request']}'),
            );
          }
        } else {
          expect(diagnosticEntries, isEmpty);
        }
        for (final entry in entries) {
          expect(entry.message, isNot(contains('SENSITIVE')));
          expect(entry.message, isNot(contains(_application.name)));
        }
        if (method == 'get_balance') {
          final invalid = XelisXswdRequest(
            kind: XelisXswdRequestKind.prefetchPermissions,
            application: _application,
            payload: xswdTestPayload({
              'permissions': ['future_method'],
            }),
          );
          expect(
            await repository.callbacks!.onPrefetchPermissionsReview!(
              invalid.prefetchPermissionsRequest!,
            ),
            isA<XelisXswdPrefetchNoChange>(),
          );
          await repository.callbacks!.onApplicationDisconnect(
            XelisXswdRequest(
              kind: XelisXswdRequestKind.applicationDisconnect,
              application: _application,
            ),
          );
          if (diagnosticLoggingEnabled) {
            final records = talker.history
                .skip(start)
                .where((entry) => entry.key == xswdDiagnosticLogKey)
                .map(
                  (entry) => jsonDecode(entry.message!) as Map<String, dynamic>,
                )
                .toList();
            final invalidRequest = records.lastWhere(
              (record) => record['event'] == 'validation',
            )['request'];
            expect(records.last['event'], 'disconnected');
            expect(records.last['request'], invalidRequest);
            expect(invalidRequest, isNot(records.first['request']));
            expect(records.last['methods'], [
              {'name': 'future_method', 'policy': 'unknown'},
            ]);
          }
        }
      },
    );
  }

  test(
    'foreign lifecycle callbacks preserve the active session decision',
    () async {
      final repository = _FakeNativeWalletRepository('a');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repository));
      final controller = container.read(xswdControllerProvider);
      expect(await controller.startXSWD(repository), isTrue);
      final firstHandler = repository.callbacks!;
      expect(await controller.addXswdRelayer(repository, _relayer), isTrue);
      final secondHandler = repository.callbacks!;
      final otherApplication = XelisXswdApplication(
        id: _application.id,
        name: 'Other connection',
        description: '',
        url: null,
        permissions: const {},
        isRelayer: true,
      );
      final activeRequest = XelisXswdRequest(
        kind: XelisXswdRequestKind.permission,
        application: _application,
        payload: xswdTestPayload(
          parseBigIntJson(
            '{"jsonrpc":"2.0","id":1,"method":"get_balance",'
            '"params":{"asset":null}}',
          ),
        ),
      );
      final decision = Future<XelisXswdDecision>.value(
        firstHandler.onPermissionRequest(activeRequest),
      );
      final pending = container.read(xswdRequestProvider).token!;

      for (final kind in [
        XelisXswdRequestKind.cancel,
        XelisXswdRequestKind.applicationDisconnect,
      ]) {
        final lifecycle = XelisXswdRequest(
          kind: kind,
          application: otherApplication,
        );
        if (kind == XelisXswdRequestKind.cancel) {
          await secondHandler.onCancelRequest(lifecycle);
        } else {
          await secondHandler.onApplicationDisconnect(lifecycle);
        }
        expect(container.read(xswdRequestProvider).pending, isTrue);
        expect(container.read(xswdRequestProvider).token, same(pending));
        final effect = container.read(walletEffectBusProvider)!.effect;
        expect(effect, isA<WalletInfoEffect>());
        expect(
          (effect as WalletInfoEffect).title,
          contains(otherApplication.name),
        );
        expect(
          container
              .read(xswdRequestProvider)
              .xswdEventSummary
              ?.application
              .sessionReference,
          _application.sessionReference,
        );
      }

      container
          .read(xswdRequestProvider.notifier)
          .resolveIfCurrent(pending, XelisXswdDecision.accept);
      expect(await decision, XelisXswdDecision.accept);
      container.read(xswdRequestProvider.notifier).clearRequest();
    },
  );

  test(
    'declined prefetch preserves the session, permissions and another approval',
    () async {
      final repository = _FakeNativeWalletRepository('a');
      final loc = AppLocalizationsEn();
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(loc),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repository));
      await container.read(xswdControllerProvider).startXSWD(repository);
      final callbacks = repository.callbacks!;
      final admission = callbacks.onApplicationRequest(
        XelisXswdRequest(
          kind: XelisXswdRequestKind.application,
          application: _application,
        ),
      );
      final token = container.read(xswdRequestProvider).token!;
      container
          .read(xswdRequestProvider.notifier)
          .resolveIfCurrent(token, XelisXswdDecision.accept);
      expect(await admission, XelisXswdDecision.accept);
      repository.xswdApplications = [_application];

      final otherApplication = XelisXswdApplication(
        id: _application.id,
        name: 'Other example app',
        description: '',
        url: null,
        permissions: const {},
        isRelayer: true,
      );
      final otherDecision = callbacks.onApplicationRequest(
        XelisXswdRequest(
          kind: XelisXswdRequestKind.application,
          application: otherApplication,
        ),
      );
      final preservedState = container.read(xswdRequestProvider);
      final logStart = talker.history.length;

      final result = await callbacks.onPrefetchPermissionsReview!(
        XelisXswdRequest(
          kind: XelisXswdRequestKind.prefetchPermissions,
          application: _application,
          payload: xswdTestPayload({
            'permissions': ['build_transaction'],
            'reason': 'SENSITIVE_REASON',
          }),
        ).prefetchPermissionsRequest!,
      );
      expect(result, isA<XelisXswdPrefetchNoChange>());
      final effect =
          container.read(walletEffectBusProvider)!.effect as WalletInfoEffect;
      expect(effect.title, loc.xswd_prefetch_not_granted(_application.name));
      expect(effect.title, isNot(contains('SENSITIVE_REASON')));
      expect(container.read(xswdRequestProvider), same(preservedState));
      expect(repository.removedApplications, isEmpty);
      expect(repository.permissionUpdates, isEmpty);
      expect(repository.xswdApplications, [_application]);
      final entries = talker.history.skip(logStart).toList();
      expect(entries.where((entry) => entry.key == supportLogKey), isEmpty);
      final diagnostics = entries.where(
        (entry) => entry.key == xswdDiagnosticLogKey,
      );
      if (diagnosticLoggingEnabled) {
        final records = diagnostics
            .map((entry) => jsonDecode(entry.message!) as Map<String, dynamic>)
            .toList();
        expect(records, hasLength(3));
        expect(
          records.map((record) => record['request']).toSet(),
          hasLength(1),
        );
        expect(records[1]['validation'], 'passed');
        expect(records[2]['decision'], 'reject');
        expect(records[2]['disposition'], 'prefetchDeclined');
        expect(
          records[2]['methods'],
          contains(
            equals({'name': 'build_transaction', 'policy': 'notPrefetchable'}),
          ),
        );
        expect(records.toString(), isNot(contains('SENSITIVE_REASON')));
        expect(records.toString(), isNot(contains(_application.name)));
      } else {
        expect(diagnostics, isEmpty);
      }
      container
          .read(xswdRequestProvider.notifier)
          .rejectIfCurrent(preservedState.token!);
      expect(await otherDecision, XelisXswdDecision.reject);

      final transaction = callbacks.onPermissionRequest(
        XelisXswdRequest(
          kind: XelisXswdRequestKind.permission,
          application: _application,
          payload: xswdTestPayload({
            'jsonrpc': '2.0',
            'method': 'build_transaction',
            'params': {
              'burn': {'asset': 'asset-hash', 'amount': 1},
            },
          }),
        ),
      );
      final transactionState = container.read(xswdRequestProvider);
      expect(transactionState.pending, isTrue);
      expect(transactionState.permissionReview!.isBuildTransaction, isTrue);
      expect(transactionState.permissionReview!.canPersist, isFalse);
      container
          .read(xswdRequestProvider.notifier)
          .resolveIfCurrent(
            transactionState.token!,
            XelisXswdDecision.alwaysAccept,
          );
      expect(await transaction, XelisXswdDecision.accept);
      expect(repository.removedApplications, isEmpty);
      expect(repository.permissionUpdates, isEmpty);
    },
  );

  test(
    'session replacement stops the origin before starting the successor',
    () async {
      final repositoryA = _FakeNativeWalletRepository('a');
      final repositoryB = _FakeNativeWalletRepository('b');
      final controller = _FakeXswdController();
      final container = _lifecycleContainer(controller);
      addTearDown(container.dispose);

      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repositoryA));
      container.listen(xswdLifecycleProvider, (_, _) {}, fireImmediately: true);
      await _waitUntil(() => controller.operations.contains('start:a'));

      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'b', repository: repositoryB));
      await _waitUntil(() => controller.operations.contains('start:b'));

      expect(
        controller.operations,
        containsAllInOrder(['start:a', 'stop:a', 'start:b']),
      );
      expect(container.read(xswdLifecycleProvider).isRunning, isTrue);
    },
  );

  test('stop wins over an in-flight relayer addition', () async {
    final repository = _FakeNativeWalletRepository('wallet');
    final controller = _FakeXswdController();
    final container = _lifecycleContainer(controller);
    addTearDown(container.dispose);

    container
        .read(activeWalletSessionProvider.notifier)
        .setSession(WalletSession(name: 'wallet', repository: repository));
    container.listen(xswdLifecycleProvider, (_, _) {}, fireImmediately: true);
    await _waitUntil(() => controller.operations.contains('start:wallet'));

    final gate = Completer<void>();
    controller.addGate = gate;
    final lifecycle = container.read(xswdLifecycleProvider.notifier);
    final addFuture = lifecycle.addRelayer(_relayer);
    await _waitUntil(() => controller.operations.contains('add:wallet'));

    final stopFuture = lifecycle.stop();
    gate.complete();

    expect(await addFuture, isFalse);
    await stopFuture;
    expect(
      controller.operations.where((entry) => entry == 'stop:wallet'),
      isNotEmpty,
    );
    expect(
      container.read(xswdLifecycleProvider).phase,
      XswdLifecyclePhase.stopped,
    );
  });

  test(
    'offline reconciliation waits for an exact application close before stop',
    () async {
      final repository = _FakeNativeWalletRepository('wallet');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'wallet', repository: repository));
      container.listen(xswdLifecycleProvider, (_, _) {}, fireImmediately: true);
      await _waitUntil(() => repository.callbacks != null);

      final closeGate = Completer<void>();
      repository.removeGate = closeGate;
      final close = container
          .read(xswdControllerProvider)
          .closeXswdAppConnection(_application);
      await _waitUntil(() => repository.removedApplications.isNotEmpty);

      container.updateOverrides([
        appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
        settingsProvider.overrideWithValue(
          const SettingsState(
            locale: Locale('en'),
            enableXswd: true,
            walletOfflineMode: true,
          ),
        ),
        walletRuntimeProvider.overrideWithValue(_connectedRuntime),
        xswdNotificationServiceProvider.overrideWithValue(
          _FakeXswdNotificationService(),
        ),
      ]);
      await _waitUntil(
        () =>
            container.read(xswdLifecycleProvider).phase ==
            XswdLifecyclePhase.stopping,
      );
      expect(repository.stopCalls, 0);

      closeGate.complete();
      await close;
      await _waitUntil(() => repository.stopCalls == 1);
      await _waitUntil(
        () =>
            container.read(xswdLifecycleProvider).phase ==
            XswdLifecyclePhase.stopped,
      );
      expect(repository.stopCalls, 1);
    },
  );

  test(
    'application close follows a successful active repository stop',
    () async {
      final repository = _FakeNativeWalletRepository('wallet');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'wallet', repository: repository));
      final stopGate = Completer<void>();
      repository.stopGate = stopGate;

      final controller = container.read(xswdControllerProvider);
      final stop = controller.stopXSWD(repository);
      await _waitUntil(() => repository.stopCalls == 1);
      final close = controller.closeXswdAppConnection(_application);

      expect(repository.removedApplications, isEmpty);
      stopGate.complete();
      expect(await stop, isTrue);
      await close;
      expect(repository.removedApplications, isEmpty);
    },
  );

  test(
    'application close retries exactly after an active stop fails',
    () async {
      final repository = _FakeNativeWalletRepository('wallet');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'wallet', repository: repository));
      final stopGate = Completer<void>();
      repository
        ..stopGate = stopGate
        ..stopError = StateError('stop failed');

      final controller = container.read(xswdControllerProvider);
      final stop = controller.stopXSWD(repository);
      await _waitUntil(() => repository.stopCalls == 1);
      final close = controller.closeXswdAppConnection(_application);

      expect(repository.removedApplications, isEmpty);
      stopGate.complete();
      expect(await stop, isFalse);
      await close;
      expect(repository.removedApplications, [_application.sessionReference]);
    },
  );

  test(
    'deferred close for a replaced repository has no successor UI effect',
    () async {
      final repositoryA = _FakeNativeWalletRepository('a');
      final repositoryB = _FakeNativeWalletRepository('b');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repositoryA));
      final effects = <WalletEffectEnvelope?>[];
      final subscription = container.listen(
        walletEffectBusProvider,
        (_, next) => effects.add(next),
      );
      addTearDown(subscription.close);
      final stopGate = Completer<void>();
      final closeGate = Completer<void>();
      repositoryA
        ..stopGate = stopGate
        ..stopError = StateError('stop failed')
        ..removeGate = closeGate;

      final controller = container.read(xswdControllerProvider);
      final stop = controller.stopXSWD(repositoryA);
      await _waitUntil(() => repositoryA.stopCalls == 1);
      final close = controller.closeXswdAppConnection(_application);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'b', repository: repositoryB));

      stopGate.complete();
      expect(await stop, isFalse);
      await _waitUntil(() => repositoryA.removedApplications.isNotEmpty);
      final effectsAfterStop = effects.length;
      closeGate.complete();
      await close;

      expect(repositoryA.removedApplications, [_application.sessionReference]);
      expect(effects, hasLength(effectsAfterStop));
      expect(
        container.read(activeWalletSessionProvider)?.repository,
        same(repositoryB),
      );
    },
  );

  test(
    'callbacks reject stale sessions and report malformed payload once',
    () async {
      final repositoryA = _FakeNativeWalletRepository('a');
      final repositoryB = _FakeNativeWalletRepository('b');
      final container = ProviderContainer(
        overrides: [
          appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
          settingsProvider.overrideWithValue(
            const SettingsState(locale: Locale('en'), enableXswd: true),
          ),
          walletRuntimeProvider.overrideWithValue(_connectedRuntime),
          xswdNotificationServiceProvider.overrideWithValue(
            _FakeXswdNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'a', repository: repositoryA));

      final effects = <WalletEffect>[];
      container.listen<WalletEffectEnvelope?>(walletEffectBusProvider, (
        _,
        next,
      ) {
        if (next != null) effects.add(next.effect);
      });
      final controller = container.read(xswdControllerProvider);
      expect(await controller.startXSWD(repositoryA), isTrue);
      final callbacks = repositoryA.callbacks!;
      repositoryA
        ..xswdApplications = [_application]
        ..xswdStateReads = 0
        ..requireStateReadBeforeRemove = true;

      final malformedDecision = await Future<XelisXswdDecision>.value(
        callbacks.onPermissionRequest(
          XelisXswdRequest(
            kind: XelisXswdRequestKind.permission,
            application: _application,
            payload: const XelisXswdStringValue('invalid-root'),
          ),
        ),
      );
      expect(malformedDecision, XelisXswdDecision.reject);
      expect(repositoryA.removedApplications, isEmpty);
      await _waitUntil(() => repositoryA.removedApplications.isNotEmpty);
      expect(repositoryA.removedApplications, [_application.sessionReference]);
      expect(repositoryA.xswdStateReads, 1);
      expect(effects.whereType<WalletFailureEffect>(), hasLength(1));

      container.read(xswdRequestProvider.notifier).clearRequest();
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(WalletSession(name: 'b', repository: repositoryB));
      final staleDecision = await Future<XelisXswdDecision>.value(
        callbacks.onApplicationRequest(
          XelisXswdRequest(
            kind: XelisXswdRequestKind.application,
            application: _application,
          ),
        ),
      );

      expect(staleDecision, XelisXswdDecision.reject);
      expect(container.read(xswdRequestProvider).xswdEventSummary, isNull);
      expect(effects.whereType<WalletFailureEffect>(), hasLength(1));
    },
  );
}

ProviderContainer _connectedXswdContainer(
  _FakeNativeWalletRepository repository, {
  XswdDecisionClock? clock,
}) {
  final container = ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      settingsProvider.overrideWithValue(
        const SettingsState(locale: Locale('en'), enableXswd: true),
      ),
      walletRuntimeProvider.overrideWithValue(_connectedRuntime),
      xswdNotificationServiceProvider.overrideWithValue(
        _FakeXswdNotificationService(),
      ),
      if (clock != null) xswdDecisionClockProvider.overrideWithValue(clock),
    ],
  );
  container
      .read(activeWalletSessionProvider.notifier)
      .setSession(WalletSession(name: 'a', repository: repository));
  return container;
}

final class _FakeXswdDecisionClock implements XswdDecisionClock {
  Duration _now = Duration.zero;
  final List<_FakeXswdScheduledTask> _tasks = [];

  @override
  Duration now() => _now;

  @override
  XswdScheduledTask schedule(Duration delay, void Function() callback) {
    final task = _FakeXswdScheduledTask(_now + delay, callback);
    _tasks.add(task);
    return task;
  }

  void advance(Duration duration) {
    _now += duration;
    for (final task in List<_FakeXswdScheduledTask>.of(_tasks)) {
      if (!task.cancelled && !task.fired && task.deadline <= _now) task.fire();
    }
  }
}

final class _FakeXswdScheduledTask implements XswdScheduledTask {
  _FakeXswdScheduledTask(this.deadline, this._callback);

  final Duration deadline;
  final void Function() _callback;
  bool cancelled = false;
  bool fired = false;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  void cancel() => cancelled = true;

  void fire() {
    fired = true;
    _callback();
  }
}

ProviderContainer _lifecycleContainer(_FakeXswdController controller) {
  return ProviderContainer(
    overrides: [
      appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
      settingsProvider.overrideWithValue(
        const SettingsState(locale: Locale('en'), enableXswd: true),
      ),
      walletRuntimeProvider.overrideWithValue(_connectedRuntime),
      xswdControllerProvider.overrideWithValue(controller),
      xswdNotificationServiceProvider.overrideWithValue(
        _FakeXswdNotificationService(),
      ),
    ],
  );
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Timed out waiting for the expected XSWD transition');
}

final _connectedRuntime = WalletRuntimeState(
  isOnline: true,
  connectionPhase: WalletConnectionPhase.connected,
  address: 'wallet-address',
  network: XelisNetwork.mainnet,
  topoheight: BigInt.zero,
  xelisBalance: BigInt.zero,
  trackedBalances: LinkedHashMap(),
  knownAssets: LinkedHashMap(),
);

final _application = XelisXswdApplication(
  id: 'app-id',
  name: 'Test app',
  description: 'Test application',
  url: null,
  permissions: const {},
  isRelayer: false,
);

final _relayer = XelisXswdRelayer(
  id: 'app-id',
  name: 'Test app',
  description: 'Test application',
  url: null,
  permissions: const [],
  relayer: 'wss://relay.example.test/session',
);

final class _FakeNativeWalletRepository implements NativeWalletRepository {
  _FakeNativeWalletRepository(this.label);

  final String label;
  XelisXswdCallbacks? callbacks;
  List<XelisXswdApplication> xswdApplications = const [];
  final List<XelisXswdSessionReference> removedApplications = [];
  final List<Map<String, XelisXswdPermissionPolicy>> permissionUpdates = [];
  Completer<void>? removeGate;
  Completer<void>? stopGate;
  Completer<void>? stateReadGate;
  Object? stateReadError;
  Completer<void>? permissionUpdateGate;
  int? permissionUpdateErrorAt;
  Object? stopError;
  int stopCalls = 0;
  int xswdStateReads = 0;
  bool requireStateReadBeforeRemove = false;

  @override
  String get address => 'wallet-address';

  @override
  XelisNetwork get network => XelisNetwork.mainnet;

  @override
  Future<void> startXSWD({required XelisXswdCallbacks callbacks}) async {
    this.callbacks = callbacks;
  }

  @override
  Future<XelisXswdState> getXswdState() async {
    xswdStateReads++;
    final snapshot = List<XelisXswdApplication>.unmodifiable(xswdApplications);
    await stateReadGate?.future;
    if (stateReadError case final error?) throw error;
    return XelisXswdState(isRunning: false, applications: snapshot);
  }

  @override
  Future<void> stopXSWD() async {
    stopCalls++;
    await stopGate?.future;
    final error = stopError;
    if (error != null) throw error;
  }

  @override
  Future<void> addXswdRelayer({
    required XelisXswdCallbacks callbacks,
    required XelisXswdRelayer relayerData,
  }) async {
    this.callbacks = callbacks;
  }

  @override
  Future<void> removeXswdApp(XelisXswdApplication application) async {
    if (requireStateReadBeforeRemove && xswdStateReads == 0) {
      throw StateError('fresh XSWD state was not read before removal');
    }
    removedApplications.add(application.sessionReference);
    await removeGate?.future;
  }

  @override
  Future<XelisXswdApplication> updateXswdApplicationPermission({
    required XelisXswdApplication application,
    required String permission,
    required XelisXswdPermissionPolicy policy,
  }) async {
    permissionUpdates.add({permission: policy});
    if (permissionUpdateErrorAt == permissionUpdates.length) {
      throw StateError('Simulated native update failure');
    }
    await permissionUpdateGate?.future;
    return application;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeXswdController implements XswdController {
  final List<String> operations = [];
  Completer<void>? addGate;

  @override
  Future<bool> startXSWD(NativeWalletRepository repository) async {
    operations.add(
      'start:${(repository as _FakeNativeWalletRepository).label}',
    );
    return true;
  }

  @override
  Future<bool> stopXSWD(NativeWalletRepository repository) async {
    operations.add('stop:${(repository as _FakeNativeWalletRepository).label}');
    return true;
  }

  @override
  Future<bool> addXswdRelayer(
    NativeWalletRepository repository,
    XelisXswdRelayer relayerData,
  ) async {
    operations.add('add:${(repository as _FakeNativeWalletRepository).label}');
    final gate = addGate;
    if (gate != null) await gate.future;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeXswdNotificationService extends XswdNotificationService {
  _FakeXswdNotificationService() : super(onApprovalOpen: () {});

  @override
  Future<void> sync({required bool active, required String title}) async {}

  @override
  Future<void> showPendingApproval({
    required String title,
    required String appName,
    required String body,
    required Object owner,
  }) async {}

  @override
  Future<void> clearPendingApproval({Object? owner}) async {}
}
