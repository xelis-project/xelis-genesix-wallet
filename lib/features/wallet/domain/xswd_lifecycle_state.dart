enum XswdLifecyclePhase { stopped, starting, running, stopping, failed }

class XswdLifecycleState {
  const XswdLifecycleState({
    this.phase = XswdLifecyclePhase.stopped,
    this.desiredEnabled = false,
    this.error,
  });

  final XswdLifecyclePhase phase;
  final bool desiredEnabled;
  final Object? error;

  bool get isRunning => phase == XswdLifecyclePhase.running;
  bool get isStarting => phase == XswdLifecyclePhase.starting;
  bool get isStopping => phase == XswdLifecyclePhase.stopping;
  bool get hasFailed => phase == XswdLifecyclePhase.failed;

  XswdLifecycleState copyWith({
    XswdLifecyclePhase? phase,
    bool? desiredEnabled,
    Object? error,
    bool clearError = false,
  }) {
    return XswdLifecycleState(
      phase: phase ?? this.phase,
      desiredEnabled: desiredEnabled ?? this.desiredEnabled,
      error: clearError ? null : error ?? this.error,
    );
  }
}
