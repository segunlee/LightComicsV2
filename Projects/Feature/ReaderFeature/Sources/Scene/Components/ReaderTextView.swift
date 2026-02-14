import CoreText
import UIKit

// MARK: - ReaderTextView

final class ReaderTextView: UIView {
  // MARK: - Properties

  var attributedString: NSAttributedString? {
    didSet { setNeedsDisplay() }
  }

  // MARK: - Drawing

  override var bounds: CGRect {
    didSet { setNeedsDisplay() }
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return super.draw(rect) }
    guard let attributedString else { return super.draw(rect) }

    context.textMatrix = CGAffineTransform.identity
    context.translateBy(x: 0, y: bounds.size.height)
    context.scaleBy(x: 1.0, y: -1.0)

    let path = CGMutablePath()
    path.addRect(bounds)
    let frameSetter = CTFramesetterCreateWithAttributedString(attributedString)
    let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attributedString.length), path, nil)
    CTFrameDraw(frame, context)
  }
}
