import FileSystemCoreInterface
import FinderDomainInterface
import Swinject

public final class FinderDomainAssembly: Assembly {
  public init() {}

  public func assemble(container: Container) {
    container.register(FinderDomainInterface.self) { resolver in
      guard let fileSystemCore = resolver.resolve(FileSystemCoreInterface.self) else {
        fatalError("FileSystemCoreInterface not registered")
      }
      return FinderDomain(fileSystemCore: fileSystemCore)
    }
  }
}
