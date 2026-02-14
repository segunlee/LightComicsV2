import Logger
import UIKit

@MainActor
final class SceneConfigurationService: AppDelegateService {

  // MARK: AppDelegateService

  func applicationConfigurationForConnecting(_ application: UIApplication, connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration? {
    Log.info("SceneConfigurationService: configuring scene")
    let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    configuration.delegateClass = SceneDelegate.self
    return configuration
  }
}
