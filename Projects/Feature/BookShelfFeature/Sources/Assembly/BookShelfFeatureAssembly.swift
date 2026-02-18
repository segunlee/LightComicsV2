import ArchiveFileCoreInterface
import BookDomainInterface
import BookShelfFeatureInterface
import ReaderFeatureInterface
import Swinject

public final class BookShelfFeatureAssembly: Assembly {
  public init() {}

  public func assemble(container: Container) {
    container.register(BookShelfFeatureFactory.self) { resolver in
      guard let bookDomain = resolver.resolve(BookDomainInterface.self) else {
        fatalError("BookDomainInterface not registered")
      }
      guard let readerFactory = resolver.resolve(ReaderFeatureFactory.self) else {
        fatalError("ReaderFeatureFactory not registered")
      }
      if let archiveCore = resolver.resolve((any ArchiveFileCoreInterface).self) {
        Task { await CoverImageProvider.shared.configure(archiveCore: archiveCore) }
      }
      return BookShelfFeatureFactoryImpl(bookDomain: bookDomain, readerFactory: readerFactory)
    }.inObjectScope(.container)
  }
}
