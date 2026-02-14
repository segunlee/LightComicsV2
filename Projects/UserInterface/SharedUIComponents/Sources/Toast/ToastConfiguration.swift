import Foundation

// MARK: - ToastConfiguration

public struct ToastConfiguration: Sendable {
  // MARK: - Properties

  public let type: ToastType
  public let title: String?
  public let message: String
  public let buttonTitle: String?
  public let priority: ToastPriority
  public let buttonAction: (@Sendable () -> Void)?

  // MARK: - Initialization

  public init(
    type: ToastType,
    title: String? = nil,
    message: String,
    buttonTitle: String? = nil,
    priority: ToastPriority = .normal,
    buttonAction: (@Sendable () -> Void)? = nil
  ) {
    self.type = type
    self.title = title
    self.message = message
    self.buttonTitle = buttonTitle
    self.priority = priority
    self.buttonAction = buttonAction
  }
}
