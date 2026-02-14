import Combine
import FinderDomainInterface
import FinderFeatureInterface
import Logger
import ReaderFeatureInterface
import UIKit

// MARK: - FinderRouting

@MainActor
protocol FinderRouting: AnyObject {
  func showDirectory(_ item: FileItem)
  func showFileDetails(_ item: FileItem)
  func canShowReader(_ item: FileItem) -> Bool
  func showReader(_ item: FileItem)
  func showDirSelection(for items: [FileItem], currnetPath: String?, onSelect: @escaping (String) -> Void)
}

// MARK: - FinderCoordinator

final class FinderCoordinator: FinderRouting {
  private weak var navigationController: UINavigationController?
  private let useCase: FinderUseCase
  private let readerFactory: ReaderFeatureFactory
  private let initializerUseCase: FinderInitializerUseCase
  private var cancellable: Set<AnyCancellable> = []

  init(
    navigationController: UINavigationController,
    useCase: FinderUseCase,
    readerFactory: ReaderFeatureFactory,
    initializerUseCase: FinderInitializerUseCase
  ) {
    self.navigationController = navigationController
    self.useCase = useCase
    self.readerFactory = readerFactory
    self.initializerUseCase = initializerUseCase
  }

  @MainActor
  func start() {
    do {
      try initializerUseCase.setupDefaultDirectories()
    } catch {
      Log.error("Finder initialization failed: \(error)")
    }
    let rootViewController = makeFinderViewController(path: nil)
    navigationController?.setViewControllers([rootViewController], animated: false)
    Log.info("Finder started at Documents root")
    observeNotifications()
  }

  @MainActor
  func showDirectory(_ item: FileItem) {
    let dirName = URL(fileURLWithPath: item.path).lastPathComponent
    Log.info("Navigate to directory: \(dirName)")
    let viewController = makeFinderViewController(path: item.path)
    navigationController?.pushViewController(viewController, animated: true)
  }

  @MainActor
  func showFileDetails(_ item: FileItem) {
    Log.debug("Show file details: \(item.name)")
    let alert = UIAlertController(
      title: item.name,
      message: "File: \(item.path)",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    navigationController?.topViewController?.present(alert, animated: true)
  }

  @MainActor
  func canShowReader(_ item: FileItem) -> Bool {
    readerFactory.canOpenReader(item.path)
  }

  @MainActor
  private func showReader(filePath: String) {
    let fileName = URL(fileURLWithPath: filePath).lastPathComponent
    guard readerFactory.canOpenReader(filePath) else {
      Log.debug("Cannot open reader for: \(fileName)")
      return
    }
    Log.info("Open reader: \(fileName)")
    let viewController = readerFactory.makeReaderViewController(filePath: filePath)
    let newNavigationController = UINavigationController(rootViewController: viewController)
    newNavigationController.modalPresentationStyle = .fullScreen
    navigationController?.topViewController?.present(newNavigationController, animated: true)
  }

  @MainActor
  func showReader(_ item: FileItem) {
    showReader(filePath: item.path)
  }

  @MainActor
  func showDirSelection(for items: [FileItem], currnetPath: String? = nil, onSelect: @escaping (String) -> Void) {
    let excludedPaths = Set(items.filter(\.isDirectory).map(\.path))
    let currentPath = currnetPath ?? FinderDocumentsPath
    let basePath = NSString(string: FinderDocumentsPath).deletingLastPathComponent
    var viewControllers = [FinderDirSelectionViewController]()
    
    if !currentPath.hasPrefix(basePath) {
      viewControllers = [createFinderDirSelectionViewController(path: FinderDocumentsPath, excludedPaths: excludedPaths, onSelect: onSelect)]
    } else {
      let relativePath = currentPath.replacingOccurrences(of: basePath + "/", with: "")
      
      // 경로 컴포넌트로 ViewController 스택 생성
      let pathComponents = relativePath.split(separator: "/").map(String.init)
      
      var accumulatedPath = basePath
      viewControllers = pathComponents.map { component in
        accumulatedPath = (accumulatedPath as NSString).appendingPathComponent(component)
        return createFinderDirSelectionViewController(
          path: accumulatedPath,
          excludedPaths: excludedPaths,
          onSelect: onSelect
        )
      }
    }
    
    let modalNav = UINavigationController()
    modalNav.viewControllers = viewControllers
    navigationController?.topViewController?.present(modalNav, animated: true)
  }

  private func observeNotifications() {
    NotificationCenter.default.publisher(for: .finderShouldOpenReader)
      .receive(on: RunLoop.main)
      .sink { [weak self] notification in
        guard let filePath = notification.userInfo?[FinderNotificationKey.filePath] as? String else { return }
        self?.showReader(filePath: filePath)
      }
      .store(in: &cancellable)
  }

  @MainActor
  private func makeFinderViewController(path: String?) -> FinderViewController {
    let viewModel = FinderViewModel(useCase: useCase, path: path)
    let viewController = FinderViewController(viewModel: viewModel, router: self)
    viewController.hidesBottomBarWhenPushed = path != nil
    return viewController
  }
}

private extension FinderCoordinator {
  @MainActor
  private func createFinderDirSelectionViewController(path: String, excludedPaths: Set<String>, onSelect: @escaping (String) -> Void) -> FinderDirSelectionViewController {
    FinderDirSelectionViewController(
      useCase: useCase,
      path: path,
      excludedPaths: excludedPaths,
      onSelect: { [weak self] destination in
        self?.navigationController?.topViewController?.dismiss(animated: true) {
          onSelect(destination)
        }
      }
    )
  }
}
