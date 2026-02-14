import SwiftUI

// MARK: - ToastType

public enum ToastType: Sendable {
  case info
  case warn
  case error

  // MARK: - Properties

  var icon: String {
    switch self {
    case .info:
      return "info.circle.fill"
    case .warn:
      return "exclamationmark.triangle.fill"
    case .error:
      return "xmark.circle.fill"
    }
  }

  var iconColor: Color {
    switch self {
    case .info:
      return .blue
    case .warn:
      return .orange
    case .error:
      return .red
    }
  }
}
