import Logger
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  let diContainer = AppDIContainer()

  private lazy var composite = CompositeAppDelegate(services: [
    SceneConfigurationService()
  ])

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    Log.info("AppDelegate: didFinishLaunchingWithOptions called")
    return composite.didFinishLaunching(application, launchOptions: launchOptions)
  }

  // MARK: - UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    composite.configurationForConnecting(application, connectingSceneSession: connectingSceneSession, options: options)
      ?? UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    composite.didDiscardSceneSessions(application, sceneSessions: sceneSessions)
  }
}
