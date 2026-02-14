import BookDomain
import DatabaseCore
import DatabaseCoreInterface
import ReaderFeature
import ReaderFeatureInterface
import SwiftUI
import Swinject

// MARK: - SampleApp

@main
struct SampleApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

// MARK: - ContentView

struct ContentView: View {
  var body: some View {
    NavigationView {
      ReaderDemoView()
    }
  }
}

// MARK: - ReaderDemoView

struct ReaderDemoView: UIViewControllerRepresentable {
  func makeUIViewController(context _: Context) -> UINavigationController {
    let container = Container()

    container.register(DatabaseCoreInterface.self) { _ in
      DatabaseCore()
    }
    BookDomainAssembly().assemble(container: container)
    ReaderFeatureAssembly().assemble(container: container)

    guard let factory = container.resolve(ReaderFeatureFactory.self) else {
      fatalError("ReaderFeatureFactory not registered")
    }

    let viewController = factory.makeReaderViewController(filePath: "")
    let navigationController = UINavigationController(rootViewController: viewController)
    return navigationController
  }

  func updateUIViewController(_: UINavigationController, context _: Context) {}
}

#Preview {
  ContentView()
}
