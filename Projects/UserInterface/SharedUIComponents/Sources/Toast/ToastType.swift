// MARK: - ToastType

public enum ToastType: Sendable {
  case info
  case warn
  case error

  // MARK: - Properties

  var animationName: String {
    switch self {
    case .info:
      return "info_notification"
    case .warn, .error:
      return "error_warning"
    }
  }
}
