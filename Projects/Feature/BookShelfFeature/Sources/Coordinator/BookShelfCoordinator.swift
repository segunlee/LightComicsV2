import BookDomainInterface
import Logger
import ReaderFeatureInterface
import UIKit

// MARK: - BookShelfCoordinator

final class BookShelfCoordinator {
  private weak var navigationController: UINavigationController?
  private let useCase: BookShelfUseCase
  private let readerFactory: ReaderFeatureFactory

  init(
    navigationController: UINavigationController,
    useCase: BookShelfUseCase,
    readerFactory: ReaderFeatureFactory
  ) {
    self.navigationController = navigationController
    self.useCase = useCase
    self.readerFactory = readerFactory
  }

  @MainActor
  func start() {
    let viewModel = BookShelfViewModel(useCase: useCase)
    let viewController = BookShelfViewController(viewModel: viewModel)
    viewController.onSelectItem = { [weak self] readInfo in
      self?.showReader(readInfo: readInfo)
    }
    navigationController?.setViewControllers([viewController], animated: false)
    Log.info("BookShelf started")
  }

  @MainActor
  private func showReader(readInfo: ReadInfo) {
    guard let path = readInfo.pathString else {
      Log.debug("BookShelfCoordinator: no path for readInfo \(readInfo.id)")
      return
    }
    guard readerFactory.canOpenReader(path) else {
      Log.debug("BookShelfCoordinator: cannot open reader for \(path)")
      return
    }
    Log.info("BookShelf opening reader: \((path as NSString).lastPathComponent)")
    let viewController = readerFactory.makeReaderViewController(filePath: path)
    let nav = UINavigationController(rootViewController: viewController)
    nav.modalPresentationStyle = .fullScreen
    navigationController?.topViewController?.present(nav, animated: true)
  }
}
