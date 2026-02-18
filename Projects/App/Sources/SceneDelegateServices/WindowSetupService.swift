import BookShelfFeatureInterface
import FinderFeatureInterface
import Logger
import UIKit

@MainActor
final class WindowSetupService: SceneDelegateService {
  // MARK: Properties

  private let diContainer: AppDIContainer

  // MARK: Initialization

  init(diContainer: AppDIContainer) {
    self.diContainer = diContainer
  }

  // MARK: SceneDelegateService

  func sceneWillConnect(_ scene: UIWindowScene, session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) -> UIWindow? {
    Log.info("WindowSetupService: configuring window")

    let window = UIWindow(windowScene: scene)
    let tabBarController = UITabBarController()

    let bookShelfTab = UITab(
      title: "서재",
      image: UIImage(systemName: "books.vertical"),
      identifier: "bookshelf"
    ) { [weak self] _ in
      guard let factory = self?.diContainer.bookShelfFeatureFactory else {
        return UINavigationController()
      }
      return factory.makeBookShelfNavigationController()
    }
    bookShelfTab.preferredPlacement = .fixed

    let documentsTab = UITab(title: "Documents", image: UIImage(systemName: "folder"), identifier: "documents") { [weak self] _ in
      guard let factory = self?.diContainer.finderFeatureFactory else {
        return UINavigationController()
      }
      return factory.makeFinderNavigationController()
    }
    documentsTab.preferredPlacement = .fixed

    let finderTab = UITab(title: "Finder", image: UIImage(systemName: "folder"), identifier: "finder") { [weak self] _ in
      guard let factory = self?.diContainer.finderFeatureFactory else {
        return UINavigationController()
      }
      return factory.makeFinderNavigationController()
    }
    finderTab.preferredPlacement = .fixed

    tabBarController.tabs = [bookShelfTab, documentsTab, finderTab]
    tabBarController.mode = .tabSidebar
    tabBarController.tabBarMinimizeBehavior = .onScrollDown

    window.rootViewController = tabBarController
    window.makeKeyAndVisible()

    Log.info("WindowSetupService: window configured with TabBarController")
    return window
  }
}
