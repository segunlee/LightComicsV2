import UIKit

// MARK: - SceneDelegateService

@MainActor
protocol SceneDelegateService {
  func sceneWillConnect(_ scene: UIWindowScene, session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) -> UIWindow?
  func sceneDidOpenURLContexts(_ scene: UIScene, urlContexts: Set<UIOpenURLContext>)
}

// MARK: - Default Implementations

extension SceneDelegateService {
  func sceneWillConnect(_ scene: UIWindowScene, session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) -> UIWindow? {
    nil
  }

  func sceneDidOpenURLContexts(_ scene: UIScene, urlContexts: Set<UIOpenURLContext>) {}
}

// MARK: - CompositeSceneDelegate

@MainActor
final class CompositeSceneDelegate {
  // MARK: Properties

  private let services: [SceneDelegateService]

  // MARK: Initialization

  init(services: [SceneDelegateService]) {
    self.services = services
  }

  // MARK: Methods

  func sceneWillConnect(_ scene: UIWindowScene, session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) -> UIWindow? {
    for service in services {
      if let window = service.sceneWillConnect(scene, session: session, connectionOptions: connectionOptions) {
        return window
      }
    }
    return nil
  }

  func sceneDidOpenURLContexts(_ scene: UIScene, urlContexts: Set<UIOpenURLContext>) {
    services.forEach { $0.sceneDidOpenURLContexts(scene, urlContexts: urlContexts) }
  }
}
