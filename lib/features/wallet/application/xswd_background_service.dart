import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';

final xswdBackgroundServiceProvider = Provider<XswdBackgroundService>((ref) {
  final service = XswdBackgroundService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class XswdBackgroundService with WidgetsBindingObserver {
  XswdBackgroundService(this._ref);

  static const _androidIcon = 'ic_stat_xswd';
  static const _foregroundNotificationId = 88001;
  static const _approvalNotificationId = 88002;
  static const _foregroundPayload = 'xswd_foreground_service';
  static const _approvalPayload = 'xswd_pending_approval';
  static const _iosBackgroundChannel = MethodChannel(
    'io.xelis.app.genesix/xswd_background_service',
  );
  static const _foregroundChannelId = 'genesix_xswd_service';
  static const _foregroundChannelName = 'Connected Apps service';
  static const _foregroundChannelDescription =
      'Keeps Connected Apps available while Genesix is in the background.';
  static const _approvalChannelId = 'genesix_xswd_requests';
  static const _approvalChannelName = 'Connected App requests';
  static const _approvalChannelDescription =
      'Approval requests from Connected Apps.';

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initializing;
  bool _initialized = false;
  bool _observingLifecycle = false;
  bool _foregroundServiceRunning = false;
  AppLifecycleState _lifecycleState =
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

  Future<void> initialize() async {
    if (!_isSupportedMobilePlatform) {
      return;
    }

    if (_initialized) {
      return;
    }

    final initializing = _initializing;
    if (initializing != null) {
      return initializing;
    }

    final future = _initialize();
    _initializing = future;
    try {
      await future;
    } catch (error) {
      talker.warning('XSWD notifications initialization failed: $error');
    } finally {
      _initializing = null;
    }
  }

  Future<void> sync({required bool active}) async {
    try {
      if (!_isSupportedMobilePlatform) {
        return;
      }

      await initialize();
      if (!_initialized) {
        return;
      }

      if (!active) {
        await clearApprovalNotification();
        await _stopAndroidForegroundService();
        await _setIosBackgroundTaskActive(false);
        return;
      }

      await _ensureNotificationPermission();
      await _setIosBackgroundTaskActive(true);
      await _startAndroidForegroundService();
    } catch (error) {
      talker.warning('XSWD background service sync failed: $error');
    }
  }

  Future<void> showApprovalNotificationIfBackground() async {
    try {
      if (!_isSupportedMobilePlatform || !_isAppBackgrounded) {
        return;
      }

      await initialize();
      if (!_initialized) {
        return;
      }

      final canNotify = await _ensureNotificationPermission();
      if (!canNotify) {
        talker.warning('XSWD approval notification skipped: permission denied');
        return;
      }

      await _notifications.show(
        id: _approvalNotificationId,
        title: 'XSWD approval requested',
        body: 'Open Genesix to review the Connected App request.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _approvalChannelId,
            _approvalChannelName,
            channelDescription: _approvalChannelDescription,
            icon: _androidIcon,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.status,
            visibility: NotificationVisibility.private,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            threadIdentifier: 'genesix_xswd',
          ),
        ),
        payload: _approvalPayload,
      );
    } catch (error) {
      talker.warning('XSWD approval notification failed: $error');
    }
  }

  Future<void> clearApprovalNotification() async {
    try {
      if (!_isSupportedMobilePlatform || !_initialized) {
        return;
      }
      await _notifications.cancel(id: _approvalNotificationId);
    } catch (error) {
      talker.warning('XSWD approval notification cleanup failed: $error');
    }
  }

  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    unawaited(_disposeAsync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  Future<void> _initialize() async {
    _ensureLifecycleObserver();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_androidIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    final initialized = await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    if (initialized != true) {
      talker.warning('XSWD notifications initialization returned $initialized');
    }

    await _createAndroidChannels();
    _initialized = true;
    await _handleLaunchNotification();
  }

  Future<void> _disposeAsync() async {
    try {
      await _stopAndroidForegroundService();
    } catch (error) {
      talker.warning('XSWD background service cleanup failed: $error');
    }
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  Future<void> _handleLaunchNotification() async {
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      return;
    }

    _handlePayload(details?.notificationResponse?.payload);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  void _handlePayload(String? payload) {
    if (payload != _approvalPayload && payload != _foregroundPayload) {
      return;
    }

    final decision = _ref.read(xswdRequestProvider).decision;
    if (decision == null || decision.isCompleted) {
      return;
    }

    _ref.read(xswdRequestProvider.notifier).requestOpenDialog();
    unawaited(clearApprovalNotification());
  }

  Future<void> _createAndroidChannels() async {
    if (!_isAndroid) {
      return;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _foregroundChannelId,
        _foregroundChannelName,
        description: _foregroundChannelDescription,
        importance: Importance.low,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _approvalChannelId,
        _approvalChannelName,
        description: _approvalChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<bool> _ensureNotificationPermission() async {
    if (!_isSupportedMobilePlatform) {
      return false;
    }

    if (_isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabled = await android?.areNotificationsEnabled();
      if (enabled == true) {
        return true;
      }
      return await android?.requestNotificationsPermission() ?? false;
    }

    if (_isIos) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final current = await ios?.checkPermissions();
      if (current?.isEnabled == true && current?.isAlertEnabled == true) {
        return true;
      }
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }

    return false;
  }

  Future<void> _startAndroidForegroundService() async {
    if (!_isAndroid || _foregroundServiceRunning) {
      return;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.startForegroundService(
      id: _foregroundNotificationId,
      title: 'Genesix Connected Apps',
      body: 'XSWD is active in the background.',
      notificationDetails: const AndroidNotificationDetails(
        _foregroundChannelId,
        _foregroundChannelName,
        channelDescription: _foregroundChannelDescription,
        icon: _androidIcon,
        importance: Importance.low,
        priority: Priority.low,
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
      ),
      payload: _foregroundPayload,
      foregroundServiceTypes: {
        AndroidServiceForegroundType.foregroundServiceTypeDataSync,
      },
    );
    _foregroundServiceRunning = true;
  }

  Future<void> _setIosBackgroundTaskActive(bool active) async {
    if (!_isIos) {
      return;
    }

    await _iosBackgroundChannel.invokeMethod<void>('setActive', active);
  }

  Future<void> _stopAndroidForegroundService() async {
    if (!_isAndroid || !_initialized || !_foregroundServiceRunning) {
      return;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.stopForegroundService();
    _foregroundServiceRunning = false;
  }

  bool get _isSupportedMobilePlatform => !kIsWeb && (_isAndroid || _isIos);

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  bool get _isAppBackgrounded {
    return switch (_lifecycleState) {
      AppLifecycleState.resumed => false,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => true,
    };
  }
}
