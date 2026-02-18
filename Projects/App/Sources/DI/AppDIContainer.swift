import ArchiveFileCore
import ArchiveFileCoreInterface
import BookDomain
import BookDomainInterface
import BookShelfFeature
import BookShelfFeatureInterface
import DatabaseCore
import DatabaseCoreInterface
import FileSystemCore
import FileSystemCoreInterface
import FinderDomain
import FinderDomainInterface
import FinderFeature
import FinderFeatureInterface
import ReaderFeature
import ReaderFeatureInterface
import Swinject

final class AppDIContainer {
  private let container: Container

  init() {
    container = Container()
    assembleDependencies()
  }

  var bookShelfFeatureFactory: BookShelfFeatureFactory {
    guard let factory = container.resolve(BookShelfFeatureFactory.self) else {
      fatalError("BookShelfFeatureFactory not registered")
    }
    return factory
  }

  var finderFeatureFactory: FinderFeatureFactory {
    guard let factory = container.resolve(FinderFeatureFactory.self) else {
      fatalError("FinderFeatureFactory not registered")
    }
    return factory
  }

  var readerFeatureFactory: ReaderFeatureFactory {
    guard let factory = container.resolve(ReaderFeatureFactory.self) else {
      fatalError("ReaderFeatureFactory not registered")
    }
    return factory
  }

  private func assembleDependencies() {
    // Register Core modules first
    container.register(ArchiveFileCoreInterface.self) { _ in
      ArchiveFileCore()
    }

    container.register(FileSystemCoreInterface.self) { _ in
      FileSystemCore()
    }

    container.register(DatabaseCoreInterface.self) { _ in
      DatabaseCore()
    }

    // Register Domain modules
    FinderDomainAssembly().assemble(container: container)
    BookDomainAssembly().assemble(container: container)

    // Register Feature modules
    BookShelfFeatureAssembly().assemble(container: container)
    FinderFeatureAssembly().assemble(container: container)
    ReaderFeatureAssembly().assemble(container: container)
  }
}
