import UIKit

public protocol FinderFeatureFactory {
  @MainActor
  func makeFinderNavigationController() -> UINavigationController
}
