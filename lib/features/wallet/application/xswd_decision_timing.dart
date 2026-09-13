import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const xswdUserDecisionBudget = Duration(minutes: 3);
const xswdDecisionSafetyTimeout = Duration(seconds: 185);
const xswdNotificationTimeout = Duration(seconds: 10);

final xswdDecisionClockProvider = Provider<XswdDecisionClock>((ref) {
  return SystemXswdDecisionClock();
});

/// Monotonic time and scheduling used by the XSWD decision budget.
///
/// Keeping both operations on one injectable clock lets the application layer
/// own expiry even when no review widget is mounted, while allowing tests to
/// advance time without waiting in real time.
abstract interface class XswdDecisionClock {
  Duration now();

  XswdScheduledTask schedule(Duration delay, void Function() callback);
}

abstract interface class XswdScheduledTask {
  bool get isActive;

  void cancel();
}

final class SystemXswdDecisionClock implements XswdDecisionClock {
  SystemXswdDecisionClock() {
    _stopwatch.start();
  }

  final Stopwatch _stopwatch = Stopwatch();

  @override
  Duration now() => _stopwatch.elapsed;

  @override
  XswdScheduledTask schedule(Duration delay, void Function() callback) {
    return _SystemXswdScheduledTask(Timer(delay, callback));
  }
}

final class _SystemXswdScheduledTask implements XswdScheduledTask {
  _SystemXswdScheduledTask(this._timer);

  final Timer _timer;

  @override
  bool get isActive => _timer.isActive;

  @override
  void cancel() => _timer.cancel();
}

Duration xswdDecisionRemaining({
  required Duration deadline,
  required XswdDecisionClock clock,
}) {
  final remaining = deadline - clock.now();
  return remaining.isNegative ? Duration.zero : remaining;
}

bool xswdDecisionExpired({
  required Duration deadline,
  required XswdDecisionClock clock,
}) => clock.now() >= deadline;
