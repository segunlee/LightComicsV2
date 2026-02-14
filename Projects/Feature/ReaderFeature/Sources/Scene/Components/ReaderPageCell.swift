import UIKit

// MARK: - ReaderPageCell

final class ReaderPageCell: UICollectionViewCell {
  // MARK: - Properties

  static let identifier = "ReaderPageCell"

  let readerContentView = ReaderContentView()

  var contentIndex: Int = NSNotFound {
    didSet { readerContentView.contentIndex = contentIndex }
  }

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .clear
    backgroundColor = .clear
    readerContentView.translatesAutoresizingMaskIntoConstraints = true
    contentView.addSubview(readerContentView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()
    readerContentView.frame = bounds
  }

  // MARK: - Reuse

  override func prepareForReuse() {
    super.prepareForReuse()
    readerContentView.resetPDFView()
  }
}
