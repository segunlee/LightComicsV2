import UIKit

// MARK: - UICollectionView + EmptyView

public extension UICollectionView {
  func setEmptyView(_ reason: EmptyReason) {
    backgroundView = ListEmptyView(reason: reason)
  }

  func restoreEmptyView() {
    backgroundView = nil
  }
}
