import UIKit

// MARK: - UITableView + EmptyView

public extension UITableView {
  func setEmptyView(_ reason: EmptyReason) {
    backgroundView = ListEmptyView(reason: reason)
  }

  func restoreEmptyView() {
    backgroundView = nil
  }
}
