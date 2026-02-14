import FinderDomainInterface

// MARK: - FinderUseCase

protocol FinderUseCase: Sendable {
  func listFiles(at path: String) throws -> [FileItem]
  func createDirectory(named name: String, at path: String) throws
  func renameItem(at path: String, to newName: String) throws
  func deleteItems(at paths: [String]) throws
  func moveItems(at paths: [String], to destinationDirectory: String) throws
  func cloneItem(at path: String) throws
}

// MARK: - FinderUseCaseImpl

final class FinderUseCaseImpl: FinderUseCase {
  private let finderDomain: FinderDomainInterface

  init(finderDomain: FinderDomainInterface) {
    self.finderDomain = finderDomain
  }

  func listFiles(at path: String) throws -> [FileItem] {
    try finderDomain.listFiles(at: path)
  }

  func createDirectory(named name: String, at path: String) throws {
    try finderDomain.createDirectory(named: name, at: path)
  }

  func renameItem(at path: String, to newName: String) throws {
    try finderDomain.renameItem(at: path, to: newName)
  }

  func deleteItems(at paths: [String]) throws {
    try finderDomain.deleteItems(at: paths)
  }

  func moveItems(at paths: [String], to destinationDirectory: String) throws {
    try finderDomain.moveItems(at: paths, to: destinationDirectory)
  }

  func cloneItem(at path: String) throws {
    try finderDomain.cloneItem(at: path)
  }
}
