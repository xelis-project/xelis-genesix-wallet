import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesix/features/logger/logger.dart';
import 'package:genesix/features/wallet/application/xswd_state_providers.dart';

final xswdNotificationServiceProvider = Provider<XswdNotificationService>((
  ref,
) {
  final service = XswdNotificationService(
    onApprovalOpen: () {
      if (!ref.mounted) {
        return;
      }
      final decision = ref.read(xswdRequestProvider).decision;
      if (decision == null || decision.isCompleted) {
        return;
      }
      ref.read(xswdRequestProvider.notifier).requestOpenDialog();
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

class XswdNotificationService with WidgetsBindingObserver {
  XswdNotificationService({required this._onApprovalOpen});

  static const _androidIcon = 'ic_stat_xswd';
  static const _androidLargeIcon = 'ic_xswd_large';
  static const _foregroundNotificationId = 88001;
  static const _approvalNotificationId = 88002;
  static const _approvalPayload = 'xswd_pending_approval';
  static const _windowsLogoAsset =
      'assets/icons/png/circle/green_background_black_logo.png';
  static const _foregroundChannelId = 'genesix_xswd_service';
  static const _foregroundChannelName = 'Connected Apps service';
  static const _approvalChannelId = 'genesix_xswd_requests';
  static const _approvalChannelName = 'Connected App requests';

  void Function()? _onApprovalOpen;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void>? _initializing;
  bool _initialized = false;
  bool _observingLifecycle = false;
  bool _foregroundServiceRunning = false;
  AppLifecycleState _lifecycleState =
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

  Future<void> initialize() async {
    if (!_isSupportedPlatform || _initialized) {
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
      talker.warning('XSWD notification initialization failed: $error');
    } finally {
      _initializing = null;
    }
  }

  Future<void> requestPermissionFromUserAction() async {
    if (!_isSupportedPlatform) {
      return;
    }

    await initialize();
    if (!_initialized) {
      return;
    }

    try {
      if (_isAndroid) {
        final android = _androidNotifications;
        if (await android?.areNotificationsEnabled() != true) {
          await android?.requestNotificationsPermission();
        }
      } else if (kIsWeb) {
        await _webNotifications?.requestNotificationsPermission();
      }
    } catch (error) {
      talker.warning('XSWD notification permission request failed: $error');
    }
  }

  Future<void> sync({required bool active, required String title}) async {
    try {
      if (!_isSupportedPlatform) {
        return;
      }

      await initialize();
      if (!_initialized) {
        return;
      }

      if (!active) {
        await clearPendingApproval();
        await _stopAndroidForegroundService();
        return;
      }

      await _startAndroidForegroundService(title: title);
    } catch (error) {
      talker.warning('XSWD notification service sync failed: $error');
    }
  }

  Future<void> showPendingApproval({
    required String title,
    required String appName,
    required String body,
  }) async {
    if (!_isSupportedPlatform || !_isAppBackgrounded) {
      return;
    }

    await initialize();
    if (!_initialized || !await _canShowNotifications()) {
      return;
    }

    try {
      final notificationDetails = NotificationDetails(
        android: const AndroidNotificationDetails(
          _approvalChannelId,
          _approvalChannelName,
          icon: _androidIcon,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          visibility: NotificationVisibility.private,
          largeIcon: DrawableResourceAndroidBitmap(_androidLargeIcon),
        ),
        windows: _windowsApprovalDetails(),
      );
      await _notifications.show(
        id: _approvalNotificationId,
        title: _notificationTitle(appName: appName, fallbackTitle: title),
        body: body,
        notificationDetails: notificationDetails,
        payload: _approvalPayload,
      );
    } catch (error) {
      talker.warning('XSWD approval notification failed: $error');
    }
  }

  Future<void> clearPendingApproval() async {
    if (!_initialized) {
      return;
    }

    try {
      await _notifications.cancel(id: _approvalNotificationId);
    } catch (error) {
      talker.warning('XSWD approval notification cleanup failed: $error');
    }
  }

  void dispose() {
    _onApprovalOpen = null;
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

    final initialized = await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_androidIcon),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: WindowsInitializationSettings(
          appName: 'Genesix',
          appUserModelId: 'io.xelis.app.genesix',
          guid: 'e0e451ef-6227-43d7-8b0e-735c58c12ad8',
        ),
        web: WebInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    if (initialized != true) {
      throw StateError(
        'Notification plugin initialization returned $initialized',
      );
    }

    await _createAndroidChannels();
    _initialized = true;
    await _handleLaunchNotification();
  }

  Future<void> _disposeAsync() async {
    try {
      await _stopAndroidForegroundService();
    } catch (error) {
      talker.warning('XSWD notification service cleanup failed: $error');
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
    if (details?.didNotificationLaunchApp == true) {
      _handlePayload(details?.notificationResponse?.payload);
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  void _handlePayload(String? payload) {
    if (payload != _approvalPayload) {
      return;
    }

    _onApprovalOpen?.call();
    unawaited(clearPendingApproval());
  }

  Future<void> _createAndroidChannels() async {
    if (!_isAndroid) {
      return;
    }

    final android = _androidNotifications;
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _foregroundChannelId,
        _foregroundChannelName,
        importance: Importance.low,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _approvalChannelId,
        _approvalChannelName,
        importance: Importance.high,
      ),
    );
  }

  Future<bool> _canShowNotifications() async {
    if (_isAndroid) {
      return await _androidNotifications?.areNotificationsEnabled() ?? false;
    }
    if (kIsWeb) {
      return _webNotifications?.permissionStatus ==
          WebNotificationPermission.granted;
    }
    return true;
  }

  Future<void> _startAndroidForegroundService({required String title}) async {
    if (!_isAndroid || _foregroundServiceRunning) {
      return;
    }

    await _androidNotifications?.startForegroundService(
      id: _foregroundNotificationId,
      title: title,
      notificationDetails: const AndroidNotificationDetails(
        _foregroundChannelId,
        _foregroundChannelName,
        icon: _androidIcon,
        importance: Importance.low,
        priority: Priority.low,
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.private,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
      ),
      foregroundServiceTypes: {
        AndroidServiceForegroundType.foregroundServiceTypeDataSync,
      },
    );
    _foregroundServiceRunning = true;
  }

  Future<void> _stopAndroidForegroundService() async {
    if (!_isAndroid || !_foregroundServiceRunning) {
      return;
    }

    await _androidNotifications?.stopForegroundService();
    _foregroundServiceRunning = false;
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidNotifications {
    return _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  WebFlutterLocalNotificationsPlugin? get _webNotifications {
    return _notifications
        .resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin
        >();
  }

  bool get _isSupportedPlatform {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  WindowsNotificationDetails? _windowsApprovalDetails() {
    if (!_isWindows) {
      return null;
    }

    return WindowsNotificationDetails(
      images: [
        WindowsImage(
          WindowsImage.getAssetUri(_windowsLogoAsset),
          altText: 'Genesix',
          placement: WindowsImagePlacement.appLogoOverride,
          crop: WindowsImageCrop.circle,
        ),
      ],
    );
  }

  String _notificationTitle({
    required String appName,
    required String fallbackTitle,
  }) {
    final normalized = appName.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
    if (normalized.isEmpty) {
      return fallbackTitle;
    }
    if (normalized.length <= 80) {
      return normalized;
    }
    return '${normalized.substring(0, 77)}...';
  }

  bool get _isAppBackgrounded => _lifecycleState != AppLifecycleState.resumed;
}
