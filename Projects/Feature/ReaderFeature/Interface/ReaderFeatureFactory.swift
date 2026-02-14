import UIKit

// MARK: - ReaderFeatureFactory

public protocol ReaderFeatureFactory {
  func canOpenReader(_ path: String) -> Bool

  @MainActor
  func makeReaderViewController(filePath: String) -> UIViewController
}
