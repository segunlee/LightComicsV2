import FinderDomainInterface
import FinderFeatureInterface
import ReaderFeatureInterface
import UIKit

final class FinderFeatureFactoryImpl: FinderFeatureFactory {
  private let finderDomain: FinderDomainInterface
  private let readerFactory: ReaderFeatureFactory
  private var coordinator: FinderCoordinator?

  nonisolated init(finderDomain: FinderDomainInterface, readerFactory: ReaderFeatureFactory) {
    self.finderDomain = finderDomain
    self.readerFactory = readerFactory
  }

  @MainActor
  func makeFinderNavigationController() -> UINavigationController {
    let useCase = FinderUseCaseImpl(finderDomain: finderDomain)
    let initializerUseCase = FinderInitializerUseCaseImpl(finderDomain: finderDomain)
    let navigationController = UINavigationController()
    navigationController.navigationBar.prefersLargeTitles = true
    let coordinator = FinderCoordinator(
      navigationController: navigationController,
      useCase: useCase,
      readerFactory: readerFactory,
      initializerUseCase: initializerUseCase
    )
    coordinator.start()
    self.coordinator = coordinator
    return navigationController
  }
}
