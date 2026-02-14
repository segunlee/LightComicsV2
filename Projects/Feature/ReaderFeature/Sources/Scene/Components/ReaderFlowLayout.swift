import UIKit

// MARK: - ReaderFlowLayout

final class ReaderFlowLayout: UICollectionViewFlowLayout {
  // MARK: - Properties

  private var focusedIndexPath: IndexPath?
  var activeFocusedIndexPath: Bool = true

  // MARK: - Animated Bounds Change

  override func prepare(forAnimatedBoundsChange oldBounds: CGRect) {
    super.prepare(forAnimatedBoundsChange: oldBounds)
    guard activeFocusedIndexPath else { return }
    focusedIndexPath = collectionView?.indexPathsForVisibleItems.first
  }

  override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
    guard let indexPath = focusedIndexPath,
          let attributes = layoutAttributesForItem(at: indexPath),
          let collectionView else {
      return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
    }
    return CGPoint(
      x: attributes.frame.origin.x - collectionView.contentInset.left,
      y: attributes.frame.origin.y - collectionView.contentInset.top
    )
  }

  override func finalizeAnimatedBoundsChange() {
    super.finalizeAnimatedBoundsChange()
    focusedIndexPath = nil
  }
}
