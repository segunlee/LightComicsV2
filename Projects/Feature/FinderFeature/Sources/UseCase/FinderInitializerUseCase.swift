import FinderDomainInterface
import Foundation

// MARK: - FinderInitializerUseCase

protocol FinderInitializerUseCase: Sendable {
  func setupDefaultDirectories() throws
}

// MARK: - FinderInitializerUseCaseImpl

final class FinderInitializerUseCaseImpl: FinderInitializerUseCase {
  private let finderDomain: FinderDomainInterface

  init(finderDomain: FinderDomainInterface) {
    self.finderDomain = finderDomain
  }

  func setupDefaultDirectories() throws {
    guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return
    }
    try finderDomain.createDirectory(named: "Downloads", at: documentsURL.path)
  }
}
