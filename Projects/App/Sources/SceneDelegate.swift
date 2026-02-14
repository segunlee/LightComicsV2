import Logger
import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {
  var window: UIWindow?

  private lazy var composite: CompositeSceneDelegate = {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      Log.error("SceneDelegate: AppDelegate not found")
      return CompositeSceneDelegate(services: [])
    }
    return CompositeSceneDelegate(services: [
      WindowSetupService(diContainer: appDelegate.diContainer),
      FileImportService()
    ])
  }()

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else {
      Log.error("SceneDelegate: failed to cast scene to UIWindowScene")
      return
    }
    window = composite.sceneWillConnect(windowScene, session: session, connectionOptions: connectionOptions)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    composite.sceneDidOpenURLContexts(scene, urlContexts: URLContexts)
  }
}
