import FinderDomain
import FinderFeature
import FinderFeatureInterface
import Logger
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
      FinderDemoView()
    }
  }
}

// MARK: - FinderDemoView

struct FinderDemoView: UIViewControllerRepresentable {
  func makeUIViewController(context _: Context) -> UINavigationController {
    let container = Container()

    FinderDomainAssembly().assemble(container: container)
    FinderFeatureAssembly().assemble(container: container)

    guard let factory = container.resolve(FinderFeatureFactory.self) else {
      fatalError("FinderFeatureFactory not registered")
    }

    return factory.makeFinderNavigationController()
  }

  func updateUIViewController(_: UINavigationController, context _: Context) {}
}

#Preview {
  ContentView()
}
