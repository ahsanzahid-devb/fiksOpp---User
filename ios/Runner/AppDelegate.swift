import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
       if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
     if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["API_KEY"] as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
     application.registerForRemoteNotifications()
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

   override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if FirebaseApp.app() != nil {
      Auth.auth().setAPNSToken(deviceToken, type: .unknown)
      // FCM needs the APNs token explicitly when AppDelegate methods are overridden
      // or when plugin registration order delays Messaging swizzling.
      Messaging.messaging().apnsToken = deviceToken
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

   override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if FirebaseApp.app() != nil, Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    super.application(
      application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

   override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if FirebaseApp.app() != nil, Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
