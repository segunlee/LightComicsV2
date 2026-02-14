import SwiftUI

// MARK: - AppTheme

public enum AppTheme: String, CaseIterable, Sendable {
  case light
  case dark
  case auto
}

// MARK: - ThemeManager

public final class ThemeManager: ObservableObject, @unchecked Sendable {
  @Published public var currentTheme: AppTheme = .auto

  public init() {}

  public func setTheme(_ theme: AppTheme) {
    currentTheme = theme
  }
}
