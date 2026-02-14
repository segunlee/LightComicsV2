import ArchiveFileCoreInterface
import BookDomainInterface
import ReaderFeatureInterface
import Swinject

// MARK: - ReaderFeatureAssembly

public final class ReaderFeatureAssembly: Assembly {
  public init() {}

  public func assemble(container: Container) {
    container.register(ReaderFeatureFactory.self) { resolver in
      guard let bookDomain = resolver.resolve(BookDomainInterface.self) else {
        fatalError("BookDomainInterface not registered")
      }
      guard let archiveCore = resolver.resolve(ArchiveFileCoreInterface.self) else {
        fatalError("ArchiveFileCoreInterface not registered")
      }
      return ReaderFeatureFactoryImpl(bookDomain: bookDomain, archiveCore: archiveCore)
    }
  }
}
