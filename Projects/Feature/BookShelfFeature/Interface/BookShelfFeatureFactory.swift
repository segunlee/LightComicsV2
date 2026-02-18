import UIKit

public protocol BookShelfFeatureFactory {
  @MainActor
  func makeBookShelfNavigationController() -> UINavigationController
}
