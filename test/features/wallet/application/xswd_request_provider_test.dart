import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/authentication/application/wallet_session_providers.dart';
import 'package:genesix/features/authentication/domain/wallet_session.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/data/native_wallet_repository.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
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

ProviderContainer _container(NativeWalletRepository repository) {
  final container = ProviderContainer();
  container
      .read(activeWalletSessionProvider.notifier)
      .setSession(WalletSession(name: 'wallet', repository: repository));
  return container;
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
