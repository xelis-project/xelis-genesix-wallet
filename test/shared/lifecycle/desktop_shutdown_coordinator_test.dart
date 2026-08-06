import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/shared/lifecycle/desktop_shutdown_coordinator.dart';

void main() {
  test(
    'closes each phase in order and coalesces concurrent requests',
    () async {
      final operations = <String>[];
      final failures = <({String phase, Object error})>[];
      final sessionGate = Completer<void>();
      final coordinator = DesktopShutdownCoordinator(
        closeSession: () async {
          operations.add('session');
          await sessionGate.future;
        },
        stopLogging: () async => operations.add('logging'),
        destroyWindow: () async => operations.add('destroy'),
        allowNativeClose: () async => operations.add('allow-native-close'),
        requestNativeClose: () async => operations.add('native-close'),
        recordFailure: (phase, error, _) {
          failures.add((phase: phase, error: error));
        },
      );

      final firstClose = coordinator.close();
      final secondClose = coordinator.close();

      expect(identical(firstClose, secondClose), isTrue);
      expect(operations, ['session']);

      sessionGate.complete();
      await firstClose;

      expect(operations, [
        'session',
        'logging',
        'allow-native-close',
        'native-close',
      ]);
      expect(failures, isEmpty);
    },
  );

  test('closes the window when session shutdown times out', () async {
    final operations = <String>[];
    final failures = <({String phase, Object error})>[];
    final sessionGate = Completer<void>();
    final coordinator = DesktopShutdownCoordinator(
      closeSession: () {
        operations.add('session');
        return sessionGate.future;
      },
      stopLogging: () async => operations.add('logging'),
      destroyWindow: () async => operations.add('destroy'),
      allowNativeClose: () async => operations.add('allow-native-close'),
      requestNativeClose: () async => operations.add('native-close'),
      recordFailure: (phase, error, _) {
        failures.add((phase: phase, error: error));
      },
      sessionTimeout: const Duration(milliseconds: 20),
    );

    await coordinator.close();

    expect(operations, [
      'session',
      'logging',
      'allow-native-close',
      'native-close',
    ]);
    expect(failures, hasLength(1));
    expect(failures.single.phase, DesktopShutdownCoordinator.sessionPhase);
    expect(failures.single.error, isA<TimeoutException>());
  });

  test('closes the window when logging shutdown times out', () async {
    final operations = <String>[];
    final failures = <({String phase, Object error})>[];
    final loggingGate = Completer<void>();
    final coordinator = DesktopShutdownCoordinator(
      closeSession: () async => operations.add('session'),
      stopLogging: () {
        operations.add('logging');
        return loggingGate.future;
      },
      destroyWindow: () async => operations.add('destroy'),
      allowNativeClose: () async => operations.add('allow-native-close'),
      requestNativeClose: () async => operations.add('native-close'),
      recordFailure: (phase, error, _) {
        failures.add((phase: phase, error: error));
      },
      loggingTimeout: const Duration(milliseconds: 20),
    );

    await coordinator.close();

    expect(operations, [
      'session',
      'logging',
      'allow-native-close',
      'native-close',
    ]);
    expect(failures, hasLength(1));
    expect(failures.single.phase, DesktopShutdownCoordinator.loggingPhase);
    expect(failures.single.error, isA<TimeoutException>());
  });

  test('continues shutdown when a phase throws', () async {
    final operations = <String>[];
    final failures = <({String phase, Object error})>[];
    final coordinator = DesktopShutdownCoordinator(
      closeSession: () async {
        operations.add('session');
        throw StateError('session failure');
      },
      stopLogging: () async => operations.add('logging'),
      destroyWindow: () async => operations.add('destroy'),
      allowNativeClose: () async => operations.add('allow-native-close'),
      requestNativeClose: () async => operations.add('native-close'),
      recordFailure: (phase, error, _) {
        failures.add((phase: phase, error: error));
      },
    );

    await coordinator.close();

    expect(operations, [
      'session',
      'logging',
      'allow-native-close',
      'native-close',
    ]);
    expect(failures, hasLength(1));
    expect(failures.single.phase, DesktopShutdownCoordinator.sessionPhase);
    expect(failures.single.error, isA<StateError>());
  });

  test('falls back to destroy when the native close request fails', () async {
    final operations = <String>[];
    final failures = <({String phase, Object error})>[];
    final coordinator = DesktopShutdownCoordinator(
      closeSession: () async => operations.add('session'),
      stopLogging: () async => operations.add('logging'),
      destroyWindow: () async => operations.add('destroy'),
      allowNativeClose: () async => operations.add('allow-native-close'),
      requestNativeClose: () async {
        operations.add('native-close');
        throw StateError('native close failure');
      },
      recordFailure: (phase, error, _) {
        failures.add((phase: phase, error: error));
      },
    );

    await coordinator.close();

    expect(operations, [
      'session',
      'logging',
      'allow-native-close',
      'native-close',
      'destroy',
    ]);
    expect(failures, hasLength(1));
    expect(failures.single.phase, DesktopShutdownCoordinator.nativeClosePhase);
  });
}
