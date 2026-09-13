import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/application/xswd_decision_timing.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:genesix/features/wallet/domain/xswd_permission_review.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' show WalletEvent;
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

import '../../../helpers/xswd_test_payload.dart';

void main() {
  test(
    'the application expires an unmounted review after three minutes',
    () async {
      final repository = _Repository();
      final clock = _FakeXswdDecisionClock();
      final container = _container(repository, clock: clock);
      addTearDown(container.dispose);
      final notifier = container.read(xswdRequestProvider.notifier);
      final pending = notifier.newRequest(
        xswdEventSummary: _request(),
        message: '',
        repository: repository,
      );
      final state = container.read(xswdRequestProvider);

      expect(state.decisionDeadline, xswdUserDecisionBudget);
      expect(notifier.remainingIfCurrent(state.token!), xswdUserDecisionBudget);
      clock.advance(const Duration(minutes: 3));

      expect(await pending, XelisXswdDecision.reject);
      expect(container.read(xswdRequestProvider).pending, isFalse);
      expect(container.read(xswdRequestProvider).token, isNull);
      expect(
        container.read(xswdRecentChoicesProvider).single.outcome,
        XswdChoiceOutcome.expired,
      );
    },
  );

  test('a decision remains valid after sixty seconds', () async {
    final repository = _Repository();
    final clock = _FakeXswdDecisionClock();
    final container = _container(repository, clock: clock);
    addTearDown(container.dispose);
    final notifier = container.read(xswdRequestProvider.notifier);
    final pending = notifier.newRequest(
      xswdEventSummary: _request(),
      message: '',
      repository: repository,
    );
    final token = container.read(xswdRequestProvider).token!;

    clock.advance(const Duration(minutes: 1));
    expect(notifier.remainingIfCurrent(token), const Duration(minutes: 2));
    expect(notifier.resolveIfCurrent(token, XelisXswdDecision.accept), isTrue);
    expect(await pending, XelisXswdDecision.accept);
  });

  test('an old expiry callback cannot reject its successor', () async {
    final repository = _Repository();
    final clock = _FakeXswdDecisionClock();
    final container = _container(repository, clock: clock);
    addTearDown(container.dispose);
    final notifier = container.read(xswdRequestProvider.notifier);
    final first = notifier.newRequest(
      xswdEventSummary: _request(),
      message: '',
      repository: repository,
    );
    final firstTask = clock.tasks.single;
    clock.advance(const Duration(minutes: 1));
    final second = notifier.newRequest(
      xswdEventSummary: _request(),
      message: '',
      repository: repository,
    );
    final secondToken = container.read(xswdRequestProvider).token!;

    expect(await first, XelisXswdDecision.reject);
    firstTask.invokeEvenIfCancelled();
    expect(container.read(xswdRequestProvider).token, same(secondToken));
    expect(container.read(xswdRequestProvider).pending, isTrue);
    expect(
      notifier.remainingIfCurrent(secondToken),
      const Duration(minutes: 3),
    );
    notifier.rejectIfCurrent(secondToken);
    expect(await second, XelisXswdDecision.reject);
  });

  test(
    'partial grants capture only the reviewed selection across handover',
    () async {
      final repository = _Repository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final notifier = container.read(xswdRequestProvider.notifier);
      final source = xswdTestPrefetch(
        permissions: [
          'get_address',
          'get_balance',
          'subscribe',
          'build_transaction',
        ],
      ).source;
      const previous = {
        'get_address': XelisXswdPermissionPolicy.accept,
        'get_balance': XelisXswdPermissionPolicy.ask,
        'subscribe': XelisXswdPermissionPolicy.reject,
        'build_transaction': XelisXswdPermissionPolicy.ask,
      };
      final pending = notifier.newPrefetchRequest(
        preflight: XswdPrefetchPreflight.parse(source),
        repository: repository,
        message: '',
        currentPermissions: previous,
      );
      final token = container.read(xswdRequestProvider).token!;
      for (final invalid in [
        ['get_balance', 'build_transaction'],
        ['get_balance', 'get_balance'],
        ['get_balance', 'get_asset'],
      ]) {
        expect(notifier.resolvePrefetchIfCurrent(token, invalid), isFalse);
        expect(container.read(xswdRequestProvider).pending, isTrue);
        expect(container.read(xswdRecentChoicesProvider), isEmpty);
      }
      final selection = ['get_balance'];
      expect(notifier.resolvePrefetchIfCurrent(token, selection), isTrue);
      selection.add('subscribe');
      final successor = notifier.newRequest(
        xswdEventSummary: _request(),
        message: '',
        repository: repository,
      );
      final result = await pending as XelisXswdPrefetchGrant;
      expect(result.permissions, ['get_balance']);
      expect(notifier.resolvePrefetchIfCurrent(token, ['subscribe']), isFalse);
      final choice = container.read(xswdRecentChoicesProvider).first;
      expect(choice.grantedMethods, ['get_balance']);
      expect(choice.scope, XswdChoiceScope.connection);
      expect(previous['subscribe'], XelisXswdPermissionPolicy.reject);
      notifier.clearRequest();
      expect(await successor, XelisXswdDecision.reject);
    },
  );

  test(
    'observations ignore older sequences and lose authority with the wallet',
    () {
      final repository = _Repository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final notifier = container.read(
        xswdApplicationObservationsProvider.notifier,
      );
      final application = _request().application;
      final observed = XelisXswdApplicationStateObserved(application, 2);
      expect(notifier.record(observed), isTrue);
      expect(
        notifier.record(XelisXswdApplicationStateStale(application, 1)),
        isFalse,
      );
      expect(
        container.read(xswdApplicationObservationsProvider).values.single,
        same(observed),
      );
      expect(
        notifier.record(XelisXswdApplicationStateTimedOut(application, 3)),
        isTrue,
      );
      notifier.removeSession(application.sessionReference);
      expect(
        notifier.record(XelisXswdApplicationStateStale(application, 3)),
        isFalse,
      );
      expect(container.read(xswdApplicationObservationsProvider), isEmpty);
      notifier.record(XelisXswdApplicationStateObserved(application, 4));
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(
            WalletSession(name: 'replacement', repository: repository),
          );
      expect(container.read(xswdApplicationObservationsProvider), isEmpty);
    },
  );

  test('once choices are recorded without changing connection rules', () async {
    final repository = _Repository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final notifier = container.read(xswdRequestProvider.notifier);
    final application = XelisXswdApplication(
      id: 'sample',
      name: 'Sample App',
      description: '',
      url: null,
      permissions: const {'get_balance': XelisXswdPermissionPolicy.ask},
      isRelayer: false,
    );
    for (final decision in [
      XelisXswdDecision.accept,
      XelisXswdDecision.reject,
    ]) {
      final pending = notifier.newRequest(
        xswdEventSummary: XelisXswdRequest(
          kind: XelisXswdRequestKind.permission,
          application: application,
          payload: xswdTestPayload({
            'jsonrpc': '2.0',
            'method': 'get_balance',
            'params': {'asset': 'SENSITIVE-PARAMETER'},
          }),
        ),
        message: '',
        repository: repository,
      );
      final token = container.read(xswdRequestProvider).token!;
      expect(notifier.resolveIfCurrent(token, decision), isTrue);
      expect(await pending, decision);
      expect(notifier.resolveIfCurrent(token, decision), isFalse);
      final choice = container.read(xswdRecentChoicesProvider).first;
      expect(choice.methods, ['get_balance']);
      expect(choice.scope, XswdChoiceScope.request);
      expect(
        choice.outcome,
        decision == XelisXswdDecision.accept
            ? XswdChoiceOutcome.allowed
            : XswdChoiceOutcome.refused,
      );
      expect(choice.toString(), isNot(contains('SENSITIVE-PARAMETER')));
      expect(
        application.permissions['get_balance'],
        XelisXswdPermissionPolicy.ask,
      );
    }
    expect(container.read(xswdRecentChoicesProvider), hasLength(2));
  });

  test(
    'recent subscriptions retain only the validated event identity',
    () async {
      final repository = _Repository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final notifier = container.read(xswdRequestProvider.notifier);
      final application = _request().application;
      for (final event in [
        WalletEvent.balanceChanged,
        WalletEvent.newTransaction,
      ]) {
        final pending = notifier.newRequest(
          xswdEventSummary: XelisXswdRequest(
            kind: XelisXswdRequestKind.permission,
            application: application,
            payload: xswdTestPayload({
              'id': 1,
              'jsonrpc': '2.0',
              'method': 'subscribe',
              'params': {
                'notify': event == WalletEvent.balanceChanged
                    ? 'balance_changed'
                    : 'new_transaction',
              },
            }),
          ),
          message: '',
          repository: repository,
        );
        final token = container.read(xswdRequestProvider).token!;
        expect(
          notifier.resolveIfCurrent(token, XelisXswdDecision.accept),
          isTrue,
        );
        expect(await pending, XelisXswdDecision.accept);
        expect(
          container.read(xswdRecentChoicesProvider).first.subscriptionEvent,
          event,
        );
      }
      expect(
        container
            .read(xswdRecentChoicesProvider)
            .map((choice) => choice.subscriptionEvent),
        [WalletEvent.newTransaction, WalletEvent.balanceChanged],
      );
    },
  );

  test(
    'recent choices are bounded, session scoped and cleared with the wallet',
    () async {
      final repository = _Repository();
      final clock = _FakeXswdDecisionClock();
      final container = _container(repository, clock: clock);
      addTearDown(container.dispose);
      final notifier = container.read(xswdRequestProvider.notifier);
      final first = _request();
      final second = _request(); // Identical declared ID, different connection.
      for (var index = 0; index < 24; index++) {
        final pending = notifier.newRequest(
          xswdEventSummary: index.isEven ? first : second,
          message: '',
          repository: repository,
        );
        final token = container.read(xswdRequestProvider).token!;
        if (index == 23) {
          clock.advance(xswdUserDecisionBudget);
        } else {
          notifier.rejectIfCurrent(token);
        }
        expect(await pending, XelisXswdDecision.reject);
      }
      final choices = container.read(xswdRecentChoicesProvider);
      expect(choices, hasLength(20));
      expect(choices.first.outcome, XswdChoiceOutcome.expired);
      container
          .read(xswdRecentChoicesProvider.notifier)
          .removeSession(first.application.sessionReference);
      expect(container.read(xswdRecentChoicesProvider), hasLength(10));
      expect(
        container
            .read(xswdRecentChoicesProvider)
            .every(
              (choice) =>
                  choice.sessionReference ==
                  second.application.sessionReference,
            ),
        isTrue,
      );
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(
            WalletSession(name: 'replacement', repository: repository),
          );
      expect(container.read(xswdRecentChoicesProvider), isEmpty);
    },
  );

  test(
    'stale actions cannot change a replacement in the same XSWD session',
    () async {
      final repository = _Repository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final notifier = container.read(xswdRequestProvider.notifier);
      final request = _request();
      final first = notifier.newRequest(
        xswdEventSummary: request,
        message: '',
        repository: repository,
      );
      final tokenA = container.read(xswdRequestProvider).token!;
      final noticeA = notifier.currentNotice!;
      final second = notifier.newRequest(
        xswdEventSummary: request,
        message: '',
        repository: repository,
      );
      final tokenB = container.read(xswdRequestProvider).token!;
      expect(await first, XelisXswdDecision.reject);
      expect(identical(tokenA, tokenB), isFalse);
      expect(noticeA.token, same(tokenA));
      expect(notifier.requestOpenIfCurrent(tokenA), isFalse);
      expect(
        notifier.resolveIfCurrent(tokenA, XelisXswdDecision.accept),
        isFalse,
      );
      expect(notifier.rejectIfCurrent(tokenA), isFalse);
      expect(notifier.clearIfCurrent(tokenA), isFalse);
      notifier.setSuppressXswdToast(true, token: tokenA);
      expect(container.read(xswdRequestProvider).pending, isTrue);
      expect(container.read(xswdRequestProvider).token, same(tokenB));
      expect(container.read(xswdRequestProvider).suppressXswdToast, isFalse);
      expect(notifier.requestOpenIfCurrent(tokenB), isTrue);
      final firstIntent = container.read(xswdDialogCoordinatorProvider).intent!;
      expect(firstIntent.token, same(tokenB));
      expect(notifier.requestOpenIfCurrent(tokenB), isTrue);
      expect(
        container.read(xswdDialogCoordinatorProvider).intent!.sequence,
        greaterThan(firstIntent.sequence),
      );
      expect(
        notifier.resolveIfCurrent(tokenB, XelisXswdDecision.accept),
        isTrue,
      );
      expect(await second, XelisXswdDecision.accept);
      expect(
        notifier.resolveIfCurrent(tokenB, XelisXswdDecision.reject),
        isFalse,
      );
    },
  );

  test(
    'wallet replacement rejects the pending future and invalidates its token',
    () async {
      final repository = _Repository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final notifier = container.read(xswdRequestProvider.notifier);
      final decision = notifier.newRequest(
        xswdEventSummary: _request(),
        message: '',
        repository: repository,
      );
      final token = container.read(xswdRequestProvider).token!;
      // Reusing the repository does not preserve the authority of an old wallet session.
      container
          .read(activeWalletSessionProvider.notifier)
          .setSession(
            WalletSession(name: 'replacement', repository: repository),
          );
      expect(
        notifier.resolveIfCurrent(token, XelisXswdDecision.accept),
        isFalse,
      );
      expect(await decision, XelisXswdDecision.reject);
      expect(container.read(xswdRequestProvider).pending, isFalse);
    },
  );

  test('malformed foreign request cannot erase an existing approval', () async {
    final repository = _Repository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final notifier = container.read(xswdRequestProvider.notifier);
    final decision = notifier.newRequest(
      xswdEventSummary: _request(),
      message: '',
      repository: repository,
    );
    final token = container.read(xswdRequestProvider).token!;
    expect(
      () => notifier.newRequest(
        xswdEventSummary: XelisXswdRequest(
          kind: XelisXswdRequestKind.permission,
          application: _request().application,
        ),
        message: '',
        repository: repository,
      ),
      throwsFormatException,
    );
    expect(container.read(xswdRequestProvider).token, same(token));
    expect(container.read(xswdRequestProvider).pending, isTrue);
    final source = XelisXswdRequest(
      kind: XelisXswdRequestKind.prefetchPermissions,
      application: _request().application,
      payload: xswdTestPayload({
        'permissions': ['subscribe'],
      }),
    );
    final mismatched = XelisXswdRequest(
      kind: source.kind,
      application: source.application,
      payload: source.payload,
    );
    final preflight = XswdPrefetchPreflight.parse(source);
    expect(
      () => notifier.newRequest(
        xswdEventSummary: mismatched,
        message: '',
        repository: repository,
        preflight: preflight,
      ),
      throwsStateError,
    );
    final declined = XelisXswdRequest(
      kind: source.kind,
      application: source.application,
      payload: xswdTestPayload({
        'permissions': ['build_transaction'],
      }),
    );
    expect(
      () => notifier.newRequest(
        xswdEventSummary: declined,
        message: '',
        repository: repository,
        preflight: XswdPrefetchPreflight.parse(declined),
      ),
      throwsStateError,
    );
    expect(container.read(xswdRequestProvider).token, same(token));
    expect(notifier.rejectIfCurrent(token), isTrue);
    expect(await decision, XelisXswdDecision.reject);
  });

  test('disposal completes an outstanding decision with rejection', () async {
    final repository = _Repository();
    final container = _container(repository);
    final decision = container
        .read(xswdRequestProvider.notifier)
        .newRequest(
          xswdEventSummary: _request(),
          message: '',
          repository: repository,
        );
    container.dispose();
    expect(await decision, XelisXswdDecision.reject);
  });
}

ProviderContainer _container(
  NativeWalletRepository repository, {
  XswdDecisionClock? clock,
}) {
  final container = ProviderContainer(
    overrides: [
      if (clock != null) xswdDecisionClockProvider.overrideWithValue(clock),
    ],
  );
  container
      .read(activeWalletSessionProvider.notifier)
      .setSession(WalletSession(name: 'wallet', repository: repository));
  return container;
}

final class _FakeXswdDecisionClock implements XswdDecisionClock {
  Duration _now = Duration.zero;
  final List<_FakeXswdScheduledTask> tasks = [];

  @override
  Duration now() => _now;

  @override
  XswdScheduledTask schedule(Duration delay, void Function() callback) {
    final task = _FakeXswdScheduledTask(_now + delay, callback);
    tasks.add(task);
    return task;
  }

  void advance(Duration duration) {
    _now += duration;
    for (final task in List<_FakeXswdScheduledTask>.of(tasks)) {
      if (!task.cancelled && !task.fired && task.deadline <= _now) {
        task.fire();
      }
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

  void invokeEvenIfCancelled() => _callback();
}

XelisXswdRequest _request() => XelisXswdRequest(
  kind: XelisXswdRequestKind.application,
  application: XelisXswdApplication(
    id: 'app',
    name: 'Application',
    description: '',
    url: null,
    permissions: const {},
    isRelayer: false,
  ),
);

class _Repository implements NativeWalletRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
