// CocoaPods links FirebaseAuth / FirebaseCore separately; SPM examples use `import Firebase`.
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static var stripeWindowChannelInstalled = false
  private static var stripeChannelInstallAttempts = 0

  /// `stripe_ios` reads `UIApplication.shared.delegate?.window` when presenting PaymentSheet.
  /// Prefer the window that actually hosts the Flutter view (not just "key" or highest score).
  static func syncStripePresentationWindow() {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

    func isForegroundScene(_ ws: UIWindowScene) -> Bool {
      ws.activationState == .foregroundActive || ws.activationState == .foregroundInactive
    }

    // 1) Window where FlutterViewController.view.window === that window (most reliable).
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene, isForegroundScene(windowScene) else { continue }
      for window in windowScene.windows where !window.isHidden && window.alpha > 0.01 {
        guard let root = window.rootViewController else { continue }
        guard let fvc = findFlutterViewController(from: root) else { continue }
        guard let hostView = fvc.viewIfLoaded else { continue }
        guard hostView.window === window else { continue }
        appDelegate.window = window
        #if DEBUG
          NSLog("[Stripe] sync: using window that hosts Flutter view (isKey=%@)", window.isKeyWindow ? "YES" : "NO")
        #endif
        return
      }
    }

    // 2) Any visible window whose hierarchy contains a FlutterViewController.
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows where !window.isHidden && window.alpha > 0.01 {
        guard let root = window.rootViewController,
              findFlutterViewController(from: root) != nil else { continue }
        appDelegate.window = window
        #if DEBUG
          NSLog("[Stripe] sync: using window with Flutter VC in hierarchy")
        #endif
        return
      }
    }

    // 3) Score-based fallback
    var best: UIWindow?
    var bestScore = -1
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows where !window.isHidden {
        var score = 0
        if window.alpha > 0.01 { score += 1 }
        if window.isKeyWindow { score += 10 }
        if window.rootViewController != nil { score += 5 }
        if window.rootViewController is FlutterViewController { score += 25 }
        if findFlutterViewController(from: window.rootViewController) != nil { score += 15 }
        if score > bestScore {
          bestScore = score
          best = window
        }
      }
    }

    if let w = best {
      appDelegate.window = w
      #if DEBUG
        let hasFlutter = findFlutterViewController(from: w.rootViewController) != nil
        NSLog(
          "[Stripe] sync fallback key=%@ root=%@ flutterVC=%@",
          w.isKeyWindow ? "YES" : "NO",
          w.rootViewController != nil ? "YES" : "NO",
          hasFlutter ? "YES" : "NO")
      #endif
    } else {
      #if DEBUG
        NSLog("[Stripe] sync: no window candidate found")
      #endif
    }
  }

  /// For Flutter logs: what will `stripe_ios` see on `delegate?.window`?
  static func stripePresenterDiagnostics() -> [String: Any] {
    var map: [String: Any] = [:]
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      map["delegateIsAppDelegate"] = false
      return map
    }
    map["delegateIsAppDelegate"] = true
    guard let w = appDelegate.window else {
      map["delegateWindowNil"] = true
      return map
    }
    map["delegateWindowNil"] = false
    map["windowIsKey"] = w.isKeyWindow
    map["windowHidden"] = w.isHidden
    map["hasRootVC"] = w.rootViewController != nil
    if let root = w.rootViewController {
      map["rootClass"] = String(describing: type(of: root))
      if let fvc = findFlutterViewController(from: root) {
        map["flutterVCFound"] = true
        map["flutterViewLoaded"] = fvc.isViewLoaded
        let hostWindow: UIWindow? = fvc.viewIfLoaded?.window
        map["flutterViewHasWindow"] = hostWindow != nil
        map["flutterViewSameAsDelegateWindow"] = hostWindow === w
      } else {
        map["flutterVCFound"] = false
      }
    }
    return map
  }

  private static func findFlutterViewController(from root: UIViewController?) -> FlutterViewController? {
    guard let root = root else { return nil }
    if let f = root as? FlutterViewController { return f }
    for child in root.children {
      if let f = findFlutterViewController(from: child) { return f }
    }
    if let nav = root as? UINavigationController {
      for vc in nav.viewControllers {
        if let f = findFlutterViewController(from: vc) { return f }
      }
    }
    if let tab = root as? UITabBarController {
      if let v = tab.selectedViewController {
        if let f = findFlutterViewController(from: v) { return f }
      }
    }
    if let presented = root.presentedViewController {
      return findFlutterViewController(from: presented)
    }
    return nil
  }

  /// Registers a channel so Dart can force a sync immediately before `presentPaymentSheet`.
  static func tryInstallStripeWindowSyncChannel() {
    guard !stripeWindowChannelInstalled else { return }
    stripeChannelInstallAttempts += 1
    syncStripePresentationWindow()

    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
          let root = appDelegate.window?.rootViewController,
          let flutterVC = findFlutterViewController(from: root)
    else {
      if stripeChannelInstallAttempts < 80 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
          tryInstallStripeWindowSyncChannel()
        }
      }
      return
    }

    stripeWindowChannelInstalled = true
    let channel = FlutterMethodChannel(
      name: "fiksopp/stripe_ios",
      binaryMessenger: flutterVC.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "syncPresentationWindow":
        syncStripePresentationWindow()
        result(nil)
      case "diagnoseStripePresenter":
        result(stripePresenterDiagnostics())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    #if DEBUG
      NSLog("[Stripe] stripe_ios window sync MethodChannel installed")
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String
    let firebasePlistKey: String? = {
      guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let plist = NSDictionary(contentsOfFile: path),
            let k = plist["API_KEY"] as? String,
            !k.isEmpty else { return nil }
      return k
    }()
    let resolvedMapsKey: String? = {
      if let k = mapsKey, !k.isEmpty { return k }
      return firebasePlistKey
    }()
    if let resolvedMapsKey = resolvedMapsKey {
      GMSServices.provideAPIKey(resolvedMapsKey)
    }
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    application.registerForRemoteNotifications()

    DispatchQueue.main.async {
      Self.tryInstallStripeWindowSyncChannel()
    }
    return ok
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    Self.syncStripePresentationWindow()
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    DispatchQueue.main.async {
      Self.tryInstallStripeWindowSyncChannel()
    }
  }

  /// FlutterAppDelegate only reports `responds(to:)` for this selector when a lifecycle plugin
  /// (e.g. firebase_messaging) has registered it. Firebase Auth probes forwarding using
  /// `delegate.responds(to:)` before phone verification; if that is false, verification fails
  /// with the “swizzling disabled / forward to canHandleNotification” error even though this
  /// class implements the method.
  override func responds(to aSelector: Selector!) -> Bool {
    if aSelector
      == NSSelectorFromString(
        "application:didReceiveRemoteNotification:fetchCompletionHandler:")
    {
      return true
    }
    return super.responds(to: aSelector)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if FirebaseApp.app() != nil {
      #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
      #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
      #endif
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
    // Forward to Firebase Auth (required when AppDelegate swizzling is off or Flutter masks responds(to:)).
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    super.application(
      application,
      didReceiveRemoteNotification: userInfo,
      fetchCompletionHandler: completionHandler)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if FirebaseApp.app() != nil {
      let handled = Auth.auth().canHandle(url)
      #if DEBUG
      NSLog(
        "[PhoneAuth] AppDelegate openURL scheme=%@ canHandle=%@",
        url.scheme ?? "(nil)",
        handled ? "YES" : "NO")
      #endif
      if handled { return true }
    }
    return super.application(app, open: url, options: options)
  }
}
