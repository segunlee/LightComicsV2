import SwiftUI

// MARK: - ToastExample

/// Example usage of LiquidGlassToast
///
/// Usage in UIViewController:
/// ```swift
/// ToastManager.shared.show(
///   ToastConfiguration(
///     type: .info,
///     title: "Success",
///     message: "File uploaded successfully",
///     buttonTitle: "View",
///     priority: .normal,
///     buttonAction: {
///       // Handle button tap
///     }
///   )
/// )
/// ```
///
/// Usage in SwiftUI:
/// ```swift
/// Button("Show Toast") {
///   ToastManager.shared.show(
///     ToastConfiguration(
///       type: .error,
///       title: "Error",
///       message: "Failed to load data",
///       buttonTitle: "Retry",
///       priority: .high,
///       buttonAction: {
///         // Handle retry
///       }
///     )
///   )
/// }
/// ```
public struct ToastExample: View {
  // MARK: - Body

  public var body: some View {
    VStack(spacing: 20) {
      Text("Toast Examples")
        .font(.title)
        .padding()

      // Info Toast
      Button("Show Info Toast") {
        ToastManager.shared.show(
          ToastConfiguration(
            type: .info,
            title: "Information",
            message: "This is an informational message.",
            buttonTitle: "View",
            priority: .normal,
            buttonAction: {
              print("Info button tapped")
            }
          )
        )
      }
      .buttonStyle(.borderedProminent)

      // Warning Toast (no title)
      Button("Show Warning Toast") {
        ToastManager.shared.show(
          ToastConfiguration(
            type: .warn,
            message: "This action cannot be undone. Please proceed with caution.",
            priority: .high
          )
        )
      }
      .buttonStyle(.borderedProminent)
      .tint(.orange)

      // Error Toast
      Button("Show Error Toast") {
        ToastManager.shared.show(
          ToastConfiguration(
            type: .error,
            title: "Error",
            message: "Failed to complete the operation.",
            buttonTitle: "Retry",
            priority: .high,
            buttonAction: {
              print("Retry tapped")
            }
          )
        )
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)

      // Simple Toast (no button)
      Button("Show Simple Toast") {
        ToastManager.shared.show(
          ToastConfiguration(
            type: .info,
            message: "Operation completed successfully",
            priority: .normal
          )
        )
      }
      .buttonStyle(.bordered)
    }
    .padding()
  }
}

// MARK: - Preview

#Preview {
  ToastExample()
}
