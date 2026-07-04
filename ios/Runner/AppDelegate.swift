import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var xswdBackgroundActive = false
  private var xswdBackgroundTask: UIBackgroundTaskIdentifier = .invalid

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    registerXswdBackgroundChannel()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    super.applicationDidEnterBackground(application)
    if xswdBackgroundActive {
      beginXswdBackgroundTask()
    }
  }

  override func applicationWillEnterForeground(_ application: UIApplication) {
    endXswdBackgroundTask()
    super.applicationWillEnterForeground(application)
  }

  private func registerXswdBackgroundChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "io.xelis.app.genesix/xswd_background_service",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setActive" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let active = call.arguments as? Bool else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Expected a boolean active flag.",
            details: nil
          )
        )
        return
      }

      self?.setXswdBackgroundActive(active)
      result(nil)
    }
  }

  private func setXswdBackgroundActive(_ active: Bool) {
    xswdBackgroundActive = active
    if active {
      if UIApplication.shared.applicationState == .background {
        beginXswdBackgroundTask()
      }
    } else {
      endXswdBackgroundTask()
    }
  }

  private func beginXswdBackgroundTask() {
    if xswdBackgroundTask != .invalid {
      return
    }

    xswdBackgroundTask = UIApplication.shared.beginBackgroundTask(
      withName: "Genesix XSWD"
    ) { [weak self] in
      self?.endXswdBackgroundTask()
    }
  }

  private func endXswdBackgroundTask() {
    if xswdBackgroundTask == .invalid {
      return
    }

    UIApplication.shared.endBackgroundTask(xswdBackgroundTask)
    xswdBackgroundTask = .invalid
  }
}
