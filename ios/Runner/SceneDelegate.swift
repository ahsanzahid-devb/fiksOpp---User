import FirebaseAuth
import FirebaseCore
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  /// Keep `AppDelegate.window` aligned with the Flutter UIWindow for `stripe_ios` PaymentSheet.
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    AppDelegate.syncStripePresentationWindow()
  }

  override func sceneWillEnterForeground(_ scene: UIScene) {
    super.sceneWillEnterForeground(scene)
    AppDelegate.syncStripePresentationWindow()
  }

  /// Phone Auth / reCAPTCHA returns via the reversed client ID URL scheme. With UIScene,
  /// this may not reach `AppDelegate.application(_:open:options:)`. If Firebase Auth does
  /// not receive the URL, verification often fails with `internal-error`.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    if FirebaseApp.app() != nil {
      for context in URLContexts {
        let url = context.url
        let handled = Auth.auth().canHandle(url)
        #if DEBUG
        // If this prints canHandle=false after reCAPTCHA, phone verification will often fail with internal-error.
        NSLog(
          "[PhoneAuth] SceneDelegate openURL scheme=%@ host=%@ canHandle=%@",
          url.scheme ?? "(nil)",
          url.host ?? "(nil)",
          handled ? "YES" : "NO")
        #endif
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
