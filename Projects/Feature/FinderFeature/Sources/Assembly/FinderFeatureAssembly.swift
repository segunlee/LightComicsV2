import FinderDomainInterface
import FinderFeatureInterface
import ReaderFeatureInterface
import Swinject

public final class FinderFeatureAssembly: Assembly {
  public init() {}

  public func assemble(container: Container) {
    container.register(FinderFeatureFactory.self) { resolver in
      guard let finderDomain = resolver.resolve(FinderDomainInterface.self) else {
        fatalError("FinderDomainInterface not registered")
      }
      guard let readerFactory = resolver.resolve(ReaderFeatureFactory.self) else {
        fatalError("ReaderFeatureFactory not registered")
      }
      return FinderFeatureFactoryImpl(finderDomain: finderDomain, readerFactory: readerFactory)
    }
  }
}
