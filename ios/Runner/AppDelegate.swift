import Flutter
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
#if DEBUG
    FirebaseConfiguration.shared.setLoggerLevel(.debug)
#endif
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    NSLog("[SoraAuth] APNs token registered and passed to Firebase Auth.")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[SoraAuth] Failed to register APNs token: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification notification: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(notification) {
      NSLog("[SoraAuth] Firebase Auth handled remote notification.")
      completionHandler(.noData)
      return
    }
    NSLog("[SoraAuth] Remote notification was not handled by Firebase Auth. keys=\(notification.keys)")
    super.application(
      application,
      didReceiveRemoteNotification: notification,
      fetchCompletionHandler: completionHandler
    )
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      NSLog("[SoraAuth] Firebase Auth handled URL callback: \(url.scheme ?? "no-scheme")")
      return true
    }
    NSLog("[SoraAuth] URL callback was not handled by Firebase Auth: \(url.scheme ?? "no-scheme")")
    return super.application(app, open: url, options: options)
  }
}
