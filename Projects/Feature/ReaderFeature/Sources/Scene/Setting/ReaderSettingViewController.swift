import ReaderFeatureInterface
import UIKit

// MARK: - ReaderSettingViewController

final class ReaderSettingViewController: UIViewController {
  // MARK: - SegmentedControlType

  private enum SegmentedControlType: Int {
    case transition = 0
    case display
    case direction
    case imageContentMode
    case imageCutMode
    case imageFilterMode
  }

  private struct CardRow {
    let title: String
    let items: [String]
    let selectedIndex: Int
    let type: SegmentedControlType
  }

  // MARK: - Properties

  var options: ReaderOptions
  private let initialOptions: ReaderOptions
  var settingCompletion: ((ReaderOptions) -> Void)?
  private let scrollView = UIScrollView()
  private let stack = UIStackView()

  // MARK: - Initialization

  init(options: ReaderOptions) {
    self.options = options
    initialOptions = options
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Viewer Settings"
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(needDismiss))
    setupOptionsView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    stack.setNeedsLayout()
    stack.layoutIfNeeded()

    let size = CGSize(
      width: stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width,
      height: stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        + (navigationController?.navigationBar.frame.height ?? 60.0)
    )
    preferredContentSize = size
    scrollView.contentSize = stack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
  }

  override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    if initialOptions != options {
      settingCompletion?(options)
    }
    super.dismiss(animated: flag, completion: completion)
  }

  // MARK: - Setup

  private func setupOptionsView() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    stack.axis = .vertical
    stack.distribution = .fill
    stack.alignment = .fill
    stack.spacing = 12
    stack.isLayoutMarginsRelativeArrangement = true
    stack.layoutMargins = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
    stack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
      stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
    ])

    // General card
    let generalCard = makeCard(rows: [
      CardRow(title: "Transition", items: ["Paging", "Page Curl", "Scroll", "None"], selectedIndex: options.transition.rawValue, type: .transition),
      CardRow(title: "Display", items: ["Single", "Double"], selectedIndex: options.display.rawValue, type: .display),
      CardRow(title: "Direction", items: ["To Right", "To Left", "To Bottom"], selectedIndex: options.direction.rawValue, type: .direction)
    ])
    stack.addArrangedSubview(makeSectionHeader("General"))
    stack.addArrangedSubview(generalCard)

    // Image-specific card
    if options.contentType == .image {
      let imageCard = makeCard(rows: [
        CardRow(title: "Content Mode", items: ["Aspect Fit", "Aspect Fill", "Scroll to Fit"], selectedIndex: options.imageContentMode.rawValue, type: .imageContentMode),
        CardRow(title: "Wide Page Splitting", items: ["None", "Cut", "Cut & Reverse"], selectedIndex: options.imageCutMode.rawValue, type: .imageCutMode),
        CardRow(title: "Image Filter", items: ["None", "Contrast", "Inverted", "Grayscale"], selectedIndex: options.imageFilterMode.rawValue, type: .imageFilterMode)
      ])
      stack.addArrangedSubview(makeSectionHeader("Image"))
      stack.addArrangedSubview(imageCard)
    }
  }

  // MARK: - Card Builders

  private func makeSectionHeader(_ title: String) -> UILabel {
    let label = UILabel()
    label.text = title
    label.font = .systemFont(ofSize: 13, weight: .semibold)
    label.textColor = .secondaryLabel
    return label
  }

  private func makeCard(rows: [CardRow]) -> UIView {
    let card = UIView()
    card.backgroundColor = .secondarySystemBackground
    card.layer.cornerRadius = 12

    let cardStack = UIStackView()
    cardStack.axis = .vertical
    cardStack.spacing = 12
    cardStack.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(cardStack)
    NSLayoutConstraint.activate([
      cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
    ])

    for (index, row) in rows.enumerated() {
      if index > 0 {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        cardStack.addArrangedSubview(separator)
      }

      let rowStack = UIStackView()
      rowStack.axis = .vertical
      rowStack.spacing = 8

      let label = UILabel()
      label.text = row.title
      label.font = .systemFont(ofSize: 14, weight: .semibold)

      let segmented = UISegmentedControl(items: row.items)
      segmented.apportionsSegmentWidthsByContent = true
      segmented.tag = row.type.rawValue
      segmented.selectedSegmentIndex = row.selectedIndex
      segmented.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)

      rowStack.addArrangedSubview(label)
      rowStack.addArrangedSubview(segmented)
      cardStack.addArrangedSubview(rowStack)
    }

    return card
  }

  private func getSegmentedControl(_ type: SegmentedControlType) -> UISegmentedControl? {
    func findSegmentedControls(in view: UIView) -> [UISegmentedControl] {
      var results: [UISegmentedControl] = []
      for subview in view.subviews {
        if let sc = subview as? UISegmentedControl {
          results.append(sc)
        }
        results.append(contentsOf: findSegmentedControls(in: subview))
      }
      return results
    }
    return findSegmentedControls(in: stack)
      .first { $0.tag == type.rawValue }
  }

  // MARK: - Actions

  @objc private func needDismiss() {
    dismiss(animated: true)
  }

  @objc private func segmentedControlValueChanged(_ control: UISegmentedControl) {
    guard let type = SegmentedControlType(rawValue: control.tag) else { return }

    switch type {
    case .transition:
      guard let newValue = ReaderTransition(rawValue: control.selectedSegmentIndex) else { return }
      options.transition = newValue
      if options.contentType == .image,
         newValue != .naturalScroll,
         options.imageContentMode == .scrollToFit {
        getSegmentedControl(.imageContentMode)?.selectedSegmentIndex = ReaderImageContentMode.aspectFit.rawValue
        getSegmentedControl(.imageContentMode)?.sendActions(for: .valueChanged)
      }

    case .display:
      guard let newValue = ReaderDisplay(rawValue: control.selectedSegmentIndex) else { return }
      options.display = newValue
      if options.contentType == .image,
         newValue != .single,
         options.imageContentMode == .scrollToFit {
        getSegmentedControl(.imageContentMode)?.selectedSegmentIndex = ReaderImageContentMode.aspectFit.rawValue
        getSegmentedControl(.imageContentMode)?.sendActions(for: .valueChanged)
      }

    case .direction:
      guard let newValue = ReaderDirection(rawValue: control.selectedSegmentIndex) else { return }
      options.direction = newValue
      if options.contentType == .image,
         newValue != .toBottom,
         options.imageContentMode == .scrollToFit {
        getSegmentedControl(.imageContentMode)?.selectedSegmentIndex = ReaderImageContentMode.aspectFit.rawValue
        getSegmentedControl(.imageContentMode)?.sendActions(for: .valueChanged)
      }

    case .imageContentMode:
      guard let newValue = ReaderImageContentMode(rawValue: control.selectedSegmentIndex) else { return }
      options.imageContentMode = newValue
      if newValue == .scrollToFit {
        getSegmentedControl(.direction)?.selectedSegmentIndex = ReaderDirection.toBottom.rawValue
        getSegmentedControl(.direction)?.sendActions(for: .valueChanged)
        getSegmentedControl(.display)?.selectedSegmentIndex = ReaderDisplay.single.rawValue
        getSegmentedControl(.display)?.sendActions(for: .valueChanged)
        getSegmentedControl(.transition)?.selectedSegmentIndex = ReaderTransition.naturalScroll.rawValue
        getSegmentedControl(.transition)?.sendActions(for: .valueChanged)
      }

    case .imageCutMode:
      guard let newValue = ReaderImageCutMode(rawValue: control.selectedSegmentIndex) else { return }
      options.imageCutMode = newValue

    case .imageFilterMode:
      guard let newValue = ReaderImageFilterMode(rawValue: control.selectedSegmentIndex) else { return }
      options.imageFilterMode = newValue
    }
  }
}
