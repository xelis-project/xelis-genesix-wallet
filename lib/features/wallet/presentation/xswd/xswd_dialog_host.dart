import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/router/router.dart';
import 'package:genesix/features/settings/application/settings_state_provider.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';
import 'package:genesix/features/wallet/domain/xswd_notice.dart';
import 'package:genesix/features/wallet/domain/xswd_request_state.dart';
import 'package:genesix/features/wallet/presentation/xswd/xswd_dialog.dart';
import 'package:genesix/shared/theme/dialog_style.dart';

class XswdDialogHost extends ConsumerStatefulWidget {
  const XswdDialogHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<XswdDialogHost> createState() => _XswdDialogHostState();
}

class _XswdDialogHostState extends ConsumerState<XswdDialogHost> {
  bool _isDialogOpen = false;
  bool _openingScheduled = false;
  XswdOpenIntent? _pendingIntent;
  Object? _lastPresentedToken;
  Object? _currentToken;
  ModalRoute<void>? _dialogRoute;
  late final XswdRequest _requestNotifier;
  late final XswdDialogCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _requestNotifier = ref.read(xswdRequestProvider.notifier);
    _coordinator = ref.read(xswdDialogCoordinatorProvider.notifier);
    _currentToken = ref.read(xswdRequestProvider).token;
    ref.listenManual<XswdRequestState>(xswdRequestProvider, _onRequestChanged);
    ref.listenManual<XswdDialogState>(
      xswdDialogCoordinatorProvider,
      _onDialogOpenSignal,
      fireImmediately: true,
    );
  }

  void _onRequestChanged(XswdRequestState? previous, XswdRequestState next) {
    _currentToken = next.token;
    final route = _dialogRoute;
    if (next.token == null && route != null) _closeIfNoRequest(route);
  }

  void _closeIfNoRequest(ModalRoute<void> route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _currentToken != null ||
          !identical(_dialogRoute, route)) {
        return;
      }
      _closeRoute(route);
    });
  }

  void _onDialogOpenSignal(XswdDialogState? previous, XswdDialogState next) {
    final intent = next.intent;
    if (intent == null || identical(previous?.intent, intent)) return;
    _pendingIntent = intent;
    _scheduleDialogOpen();
  }

  void _scheduleDialogOpen() {
    if (_isDialogOpen || _openingScheduled || !mounted) return;
    _openingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openingScheduled = false;
      if (!mounted || _isDialogOpen) return;

      final intent = _pendingIntent;
      if (intent == null) return;

      final requestNotifier = _requestNotifier;
      final requestState = ref.read(xswdRequestProvider);
      if (!requestState.pending ||
          !identical(requestState.token, intent.token) ||
          !requestNotifier.isCurrent(intent.token)) {
        return;
      }
      final navigatorContext = routerKey.currentState?.overlay?.context;
      if (navigatorContext == null) return;
      if (ref.read(settingsProvider).walletOfflineMode) {
        requestNotifier.rejectIfCurrent(intent.token);
        return;
      }

      final coordinator = _coordinator;
      if (!coordinator.claimOpenRequest(intent)) return;

      _isDialogOpen = true;
      showAppDialog<void>(
        context: navigatorContext,
        builder: (context, _, animation) {
          final route = ModalRoute.of<void>(context);
          if (route?.isActive == true) {
            _dialogRoute = route;
            if (_currentToken == null) _closeIfNoRequest(route!);
          }
          return XswdDialog(
            animation,
            onRequestPresented: (token) {
              if (!mounted) return;
              _lastPresentedToken = token;
              coordinator.markPresented(token);
            },
          );
        },
      ).whenComplete(() {
        if (!mounted) return;

        _isDialogOpen = false;
        _dialogRoute = null;
        final presentedToken = _lastPresentedToken;
        _clearLastPresentedRequest();

        final currentToken = ref.read(xswdRequestProvider).token;
        if (currentToken != null && !identical(currentToken, presentedToken)) {
          requestNotifier.setSuppressXswdToast(false, token: currentToken);
        }
        _scheduleDialogOpen();
      });
    });
  }

  void _clearLastPresentedRequest() {
    final token = _lastPresentedToken;
    _lastPresentedToken = null;
    if (token == null) return;
    _coordinator.clearPresented(token);
    _requestNotifier.clearIfCurrent(token);
  }

  @override
  void dispose() {
    final presentedToken = _lastPresentedToken;
    _lastPresentedToken = null;
    final currentToken = _currentToken;
    final route = _dialogRoute;
    Future<void>.microtask(() {
      _closeRoute(route);
      if (presentedToken != null) {
        _requestNotifier.clearIfCurrent(presentedToken);
        _coordinator.clearPresented(presentedToken);
      }
      if (currentToken != null) {
        _requestNotifier.setSuppressXswdToast(false, token: currentToken);
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void _closeRoute(ModalRoute<void>? route) {
  if (route == null || !route.isActive) return;
  final navigator = route.navigator;
  if (navigator == null || !navigator.mounted) return;
  if (route.isCurrent) {
    navigator.pop();
  } else {
    navigator.removeRoute(route);
  }
}
