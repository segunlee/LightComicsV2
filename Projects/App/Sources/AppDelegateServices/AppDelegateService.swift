import UIKit

// MARK: - AppDelegateService

@MainActor
protocol AppDelegateService {
  func applicationDidFinishLaunching(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
  func applicationConfigurationForConnecting(_ application: UIApplication, connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration?
  func applicationDidDiscardSceneSessions(_ application: UIApplication, sceneSessions: Set<UISceneSession>)
}

// MARK: - Default Implementations

extension AppDelegateService {
  func applicationDidFinishLaunching(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    true
  }

  func applicationConfigurationForConnecting(_ application: UIApplication, connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration? {
    nil
  }

  func applicationDidDiscardSceneSessions(_ application: UIApplication, sceneSessions: Set<UISceneSession>) {}
}

// MARK: - CompositeAppDelegate

@MainActor
final class CompositeAppDelegate {
  // MARK: Properties

  private let services: [AppDelegateService]

  // MARK: Initialization

  init(services: [AppDelegateService]) {
    self.services = services
  }

  // MARK: Methods

  func didFinishLaunching(_ application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    services.allSatisfy { $0.applicationDidFinishLaunching(application, launchOptions: launchOptions) }
  }

  func configurationForConnecting(_ application: UIApplication, connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration? {
    for service in services {
      if let config = service.applicationConfigurationForConnecting(application, connectingSceneSession: connectingSceneSession, options: options) {
        return config
      }
    }
    return nil
  }

  func didDiscardSceneSessions(_ application: UIApplication, sceneSessions: Set<UISceneSession>) {
    services.forEach { $0.applicationDidDiscardSceneSessions(application, sceneSessions: sceneSessions) }
  }
}
