import BookDomainInterface
import DatabaseCoreInterface
import Swinject

// MARK: - BookDomainAssembly

public final class BookDomainAssembly: Assembly {
  public init() {}

  public func assemble(container: Container) {
    container.register(BookDomainInterface.self) { resolver in
      guard let databaseCore = resolver.resolve(DatabaseCoreInterface.self) else {
        fatalError("DatabaseCoreInterface not registered")
      }
      return BookDomain(databaseCore: databaseCore)
    }
  }
}
