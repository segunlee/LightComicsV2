import BookDomainInterface
import BookShelfFeatureInterface
import ReaderFeatureInterface
import UIKit

final class BookShelfFeatureFactoryImpl: BookShelfFeatureFactory {
  private let bookDomain: BookDomainInterface
  private let readerFactory: ReaderFeatureFactory
  private var coordinator: BookShelfCoordinator?

  nonisolated init(bookDomain: BookDomainInterface, readerFactory: ReaderFeatureFactory) {
    self.bookDomain = bookDomain
    self.readerFactory = readerFactory
  }

  @MainActor
  func makeBookShelfNavigationController() -> UINavigationController {
    let useCase = BookShelfUseCaseImpl(bookDomain: bookDomain)
    let navigationController = UINavigationController()
    navigationController.navigationBar.prefersLargeTitles = true
    let coordinator = BookShelfCoordinator(
      navigationController: navigationController,
      useCase: useCase,
      readerFactory: readerFactory
    )
    coordinator.start()
    self.coordinator = coordinator
    return navigationController
  }
}
