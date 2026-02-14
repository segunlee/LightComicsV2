import SwiftUI

// MARK: - SharedUIComponents

public struct SharedUIComponents {
  public init() {}
}

// MARK: - PrimaryButton

public struct PrimaryButton: View {
  let title: String
  let action: () -> Void

  public init(title: String, action: @escaping () -> Void) {
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      Text(title)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
  }
}
