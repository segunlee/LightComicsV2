import Foundation

// MARK: - Configurable

public protocol Configurable {}

public extension Configurable {
  func with(_ configure: (inout Self) -> Void) -> Self {
    var copy = self
    configure(&copy)
    return copy
  }
}
