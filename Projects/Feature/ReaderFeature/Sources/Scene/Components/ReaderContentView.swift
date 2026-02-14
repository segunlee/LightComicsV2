import PDFKit
import ReaderFeatureInterface
import UIKit

// MARK: - ReaderContentView

final class ReaderContentView: UIView {
  // MARK: - Properties

  private(set) var contentType: ReaderContentType = .image
  var options: ReaderOptions = ReaderOptions() {
    didSet { contentLayout() }
  }

  var contentIndex: Int = NSNotFound

  var pagingText: String? {
    get { pagingLabel.text }
    set { pagingLabel.text = newValue }
  }

  // MARK: - Lazy Subviews

  private lazy var scrollView: UIScrollView = {
    let sv = UIScrollView()
    sv.minimumZoomScale = 1
    sv.maximumZoomScale = 5
    sv.zoomScale = 1.0
    sv.bounces = true
    sv.decelerationRate = .fast
    sv.contentInsetAdjustmentBehavior = .never
    sv.delegate = self
    return sv
  }()

  private lazy var imageView: UIImageView = {
    let iv = UIImageView(frame: .zero)
    iv.clipsToBounds = true
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  private lazy var textView = ReaderTextView()

  private lazy var pdfView: PDFView = {
    let pv = PDFView()
    pv.autoScales = true
    pv.isAccessibilityElement = false
    pv.displayMode = .singlePage
    pv.insetsLayoutMarginsFromSafeArea = false
    return pv
  }()

  private lazy var pagingLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 10)
    label.textAlignment = .center
    return label
  }()

  // MARK: - Initialization

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Layout

  override var bounds: CGRect {
    didSet {
      guard oldValue != bounds else { return }
      contentLayout()
      afterDecoration()
    }
  }

  // MARK: - Content Layout

  private func contentLayout() {
    for subview in subviews {
      subview.removeFromSuperview()
    }

    switch options.contentType {
    case .image:
      break

    case .text:
      addSubview(textView)
      textView.translatesAutoresizingMaskIntoConstraints = true
      contentLayoutText()

    case .pdf:
      addSubview(pdfView)
      pdfView.translatesAutoresizingMaskIntoConstraints = true
    }

    addSubview(pagingLabel)
    NSLayoutConstraint.activate([
      pagingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
      pagingLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
    ])
    pagingLabel.isHidden = options.hidePagingLabel
  }

  private func contentLayoutText() {
    let conIndex = (contentIndex != NSNotFound) ? contentIndex : 0
    var rect = bounds.insetBy(dx: 16, dy: 16)

    if options.display == .double {
      switch options.direction {
      case .toBottom:
        rect = CGRect(x: 16, y: 16, width: bounds.width - 32, height: bounds.height / 2 - 16)
        if conIndex % 2 == 1 {
          rect.origin.y = bounds.height / 2 + 10
        }
      case .toRight, .toLeft:
        rect = CGRect(x: 16, y: 16, width: bounds.width / 2 - 32, height: bounds.height - 32)
        let isDirectionLeft = options.direction == .toLeft
        let isLeftContent = isDirectionLeft ? conIndex % 2 == 1 : conIndex % 2 == 0
        if !isLeftContent {
          rect.origin.x = 10
        }
      }
    }

    if options.isFullScreenVerticalScroll {
      rect = bounds
    }

    textView.frame = rect
  }

  // MARK: - Decoration

  func beforeDecoration() {
    switch options.contentType {
    case .image:
      scrollView.contentOffset = .zero
      imageView.image = nil

    case .text:
      textView.attributedString = nil

    case .pdf:
      pdfView.document = nil
    }
  }

  func afterDecoration() {
    switch options.contentType {
    case .image:
      imageView.removeFromSuperview()
      scrollView.removeFromSuperview()

      addSubview(scrollView)
      scrollView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        scrollView.topAnchor.constraint(equalTo: topAnchor),
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
      ])

      scrollView.addSubview(imageView)
      imageView.translatesAutoresizingMaskIntoConstraints = false

      switch options.imageContentMode {
      case .aspectFit, .scrollToFit:
        scrollView.bounces = true
        NSLayoutConstraint.activate([
          imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
          imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
          imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
          imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
          imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
          imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

      case .aspectFill:
        guard let size = imageView.image?.size else { return }
        scrollView.bounces = false
        let screenWidth = bounds.width
        let screenHeight = bounds.height

        NSLayoutConstraint.activate([
          imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
          imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
          imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
          imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        if size.width >= size.height {
          imageView.heightAnchor.constraint(equalToConstant: screenHeight).isActive = true
          let aspectRatio = size.width / size.height
          imageView.widthAnchor.constraint(equalToConstant: screenHeight * aspectRatio).isActive = true
        } else {
          imageView.widthAnchor.constraint(equalToConstant: screenWidth).isActive = true
          let aspectRatio = size.height / size.width
          imageView.heightAnchor.constraint(equalToConstant: screenWidth * aspectRatio).isActive = true
        }
      }

      if scrollView.zoomScale != 1.0 {
        scrollView.zoomScale = 1.0
      }

    case .text:
      contentLayoutText()

    case .pdf:
      pdfView.frame = bounds
      pdfView.autoScales = true
      pdfView.maxScaleFactor = 4.0
      pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
      let allSubviews = pdfView.subviews.flatMap { $0.subviews }
      for gestureRecognizer in allSubviews
        .compactMap(\.gestureRecognizers)
        .flatMap({ $0 })
        .filter({ $0 is UITapGestureRecognizer || $0 is UILongPressGestureRecognizer }) {
        gestureRecognizer.isEnabled = false
      }
    }

    bringSubviewToFront(pagingLabel)
  }

  func decorate(with element: ReaderContentElement, at index: Int, totalPages: Int) {
    switch element {
    case let .image(image):
      imageView.image = image
      switch options.imageContentMode {
      case .aspectFit: imageView.contentMode = .scaleAspectFit
      case .aspectFill: imageView.contentMode = .scaleAspectFill
      case .scrollToFit: imageView.contentMode = .scaleAspectFill
      }

    case let .pdf(document):
      pdfView.document = document
      pdfView.autoScales = true

    case let .text(attributedString):
      textView.attributedString = attributedString
    }

    pagingText = "\(index + 1)/\(totalPages)"
  }

  func decorateError(_ error: Error) {
    pagingText = error.localizedDescription
  }

  func resetPDFView() {
    pdfView.scaleFactor = 1.0
    pdfView.autoScales = true
  }

  // MARK: - Public Accessors

  func getImageView() -> UIImageView { imageView }
  func getScrollView() -> UIScrollView { scrollView }
  func getTextView() -> ReaderTextView { textView }
  func getPDFView() -> PDFView { pdfView }
  func getPagingLabel() -> UILabel { pagingLabel }
}

// MARK: - ReaderContentView + UIScrollViewDelegate

extension ReaderContentView: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageView
  }
}
