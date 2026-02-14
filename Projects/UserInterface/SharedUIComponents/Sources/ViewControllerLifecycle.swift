import UIKit

// MARK: - ViewControllerLifecycle

@MainActor
public protocol ViewControllerLifecycle: UIViewController {
  func setupUI()
  func setupNavigationBar()
  func bindViewModel()
  func loadInitialData()
}

// MARK: - ViewControllerLifecycle + Default Implementation

public extension ViewControllerLifecycle {
  /// Setup UI components and layout
  /// Override this method to configure views, colors, and constraints
  func setupUI() {}

  /// Setup navigation bar items and appearance
  /// Override this method to configure navigation bar buttons and title
  func setupNavigationBar() {}

  /// Bind ViewModel to View
  /// Override this method to set up data bindings (Combine, RxSwift, etc.)
  func bindViewModel() {}

  /// Load initial data
  /// Override this method to trigger initial data loading
  func loadInitialData() {}
}
