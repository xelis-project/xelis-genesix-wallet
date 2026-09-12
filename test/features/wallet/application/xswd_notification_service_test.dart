import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genesix/features/wallet/application/xswd_notification_service.dart';

const _channel = MethodChannel('dexterous.com/flutter/local_notifications');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a native tap clears its captured owner while a successor is queued',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      final native = _NativeNotifications();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_channel, native.handle);
      var opens = 0;
      final service = XswdNotificationService(onApprovalOpen: () => opens++);
      addTearDown(() {
        service.dispose();
        messenger.setMockMethodCallHandler(_channel, null);
        debugDefaultTargetPlatformOverride = null;
      });
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      final ownerA = Object();
      final ownerB = Object();
      await service.showPendingApproval(
        title: 'Approval',
        appName: 'A',
        body: 'Review',
        owner: ownerA,
      );
      expect(native.shownTitles, ['A']);

      native.cancelGate = Completer<void>();
      final delivered = Completer<void>();
      // Simulate the platform callback registered by the real plugin.
      // ignore: deprecated_member_use
      messenger.handlePlatformMessage(
        _channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('didReceiveNotificationResponse', {
            'notificationResponseType': 0,
            'payload': 'xswd_pending_approval',
          }),
        ),
        (_) => delivered.complete(),
      );
      await delivered.future;
      await native.cancelStarted.future;
      final next = service.showPendingApproval(
        title: 'Approval',
        appName: 'B',
        body: 'Review',
        owner: ownerB,
      );
      native.cancelGate!.complete();
      await next;
      expect(opens, 1);
      expect(native.shownTitles, ['A', 'B']);
      final cancels = native.cancels;
      await service.clearPendingApproval(owner: ownerA);
      expect(native.cancels, cancels);
      await service.clearPendingApproval(owner: ownerB);
      expect(native.cancels, cancels + 1);
    },
  );
}

class _NativeNotifications {
  final shownTitles = <String>[];
  final cancelStarted = Completer<void>();
  Completer<void>? cancelGate;
  int cancels = 0;

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'initialize':
      case 'areNotificationsEnabled':
        return true;
      case 'getNotificationAppLaunchDetails':
        return {'notificationLaunchedApp': false};
      case 'show':
        shownTitles.add((call.arguments as Map)['title'] as String);
      case 'cancel':
        cancels++;
        if (!cancelStarted.isCompleted) cancelStarted.complete();
        await cancelGate?.future;
    }
    return null;
  }
}
