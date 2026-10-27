import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Needed by flutter_local_notifications so foreground notification
    // presentation / taps are routed through the plugin. firebase_messaging
    // keeps its default method swizzling (FirebaseAppDelegateProxyEnabled is
    // not disabled), and Firebase itself is configured from Dart via
    // Firebase.initializeApp(), which reads GoogleService-Info.plist.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
