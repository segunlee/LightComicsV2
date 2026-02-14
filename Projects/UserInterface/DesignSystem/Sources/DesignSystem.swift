import SwiftUI
import UIKit

// MARK: - DesignSystem

public struct DesignSystem {
  public init() {}
}

public extension Color {
  static let primaryBackground = Color(UIColor.systemBackground)
  static let secondaryBackground = Color(UIColor.secondarySystemBackground)
}

public extension Font {
  static let title = Font.system(size: 24, weight: .bold)
  static let body = Font.system(size: 16, weight: .regular)
}
