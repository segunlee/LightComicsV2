import Foundation
import ReaderFeatureInterface

// MARK: - ReaderOptions

struct ReaderOptions: Equatable, Sendable {
  var transition: ReaderTransition
  var contentType: ReaderContentType
  var direction: ReaderDirection
  var display: ReaderDisplay
  var imageContentMode: ReaderImageContentMode
  var imageCutMode: ReaderImageCutMode
  var imageFilterMode: ReaderImageFilterMode
  var touchPointLR: Bool
  var hidePagingLabel: Bool

  init(
    transition: ReaderTransition = .paging,
    contentType: ReaderContentType = .image,
    direction: ReaderDirection = .toRight,
    display: ReaderDisplay = .single,
    imageContentMode: ReaderImageContentMode = .aspectFit,
    imageCutMode: ReaderImageCutMode = .none,
    imageFilterMode: ReaderImageFilterMode = .none,
    touchPointLR: Bool = true,
    hidePagingLabel: Bool = false
  ) {
    self.transition = transition
    self.contentType = contentType
    self.direction = direction
    self.display = display
    self.imageContentMode = imageContentMode
    self.imageCutMode = imageCutMode
    self.imageFilterMode = imageFilterMode
    self.touchPointLR = touchPointLR
    self.hidePagingLabel = hidePagingLabel
  }

  var isFullScreenVerticalScroll: Bool {
    transition == .naturalScroll && display == .single && direction == .toBottom
  }

  static func == (lhs: ReaderOptions, rhs: ReaderOptions) -> Bool {
    lhs.transition == rhs.transition &&
      lhs.contentType == rhs.contentType &&
      lhs.direction == rhs.direction &&
      lhs.display == rhs.display &&
      lhs.imageContentMode == rhs.imageContentMode &&
      lhs.imageCutMode == rhs.imageCutMode &&
      lhs.imageFilterMode == rhs.imageFilterMode
  }
}
