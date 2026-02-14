import Foundation

// MARK: - ToastPriority

public enum ToastPriority: Sendable {
  case normal
  case high

  // MARK: - Properties

  var duration: TimeInterval {
    switch self {
    case .normal:
      return 2.0
    case .high:
      return 3.0
    }
  }
}
