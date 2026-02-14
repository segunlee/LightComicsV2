import Combine
import ReaderFeatureInterface
import SharedUIComponents
import UIKit

// MARK: - ReaderViewController

final class ReaderViewController: UIViewController, ViewControllerLifecycle {
  // MARK: - Properties

  let viewModel: ReaderViewModel
  let collectionView: UICollectionView
  private let collectionViewLayout = ReaderFlowLayout()
  private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(didTapCollectionView(_:)))
  private lazy var loadingIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.color = .white
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = true
    return indicator
  }()

  let pagingLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    label.layer.cornerRadius = 12
    label.layer.masksToBounds = true
    label.isUserInteractionEnabled = true
    return label
  }()

  let toolbar: UIToolbar = {
    let bar = UIToolbar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    bar.barStyle = .black
    bar.isTranslucent = true
    bar.isHidden = true
    return bar
  }()

  var cancellable: Set<AnyCancellable> = []

  // MARK: - Initialization

  init(viewModel: ReaderViewModel) {
    self.viewModel = viewModel
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    super.init(nibName: nil, bundle: nil)
    viewModel.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupNavigationBar()
    setupCollectionView()
    bindViewModel()
    loadInitialData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopSpeech()
    viewModel.saveCurrentState()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    if let pdfProvider = viewModel.dataProvider as? ReaderPDFDataProvider {
      pdfProvider.recreatePDFDocument()
    }
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    let index = viewModel.state.currentIndex
    let options = viewModel.state.options

    if options.contentType == .text {
      let textCanvasSize = textCanvasSize(for: size)
      viewModel.send(.refetchForTextRotation(textCanvasSize))
    }

    coordinator.animate { [weak self] _ in
      self?.collectionViewInsetsUpdate()
    } completion: { [weak self] _ in
      guard let self else { return }
      collectionViewInsetsUpdate()

      var newOffset = CGPoint.zero
      switch options.direction {
      case .toRight:
        newOffset = CGPoint(x: CGFloat(index) * size.width, y: 0)
      case .toLeft:
        let totalWidth = size.width * CGFloat(collectionView.numberOfItems(inSection: 0)) - size.width
        newOffset = CGPoint(x: totalWidth - (CGFloat(index) * size.width), y: 0)
      case .toBottom:
        newOffset = CGPoint(x: 0, y: CGFloat(index) * size.height)
      }
      collectionView.reloadData()
      collectionView.setContentOffset(newOffset, animated: false)
    }
  }

  // MARK: - ViewControllerLifecycle

  func setupUI() {
    view.backgroundColor = .black
    view.addSubview(loadingIndicator)
    NSLayoutConstraint.activate([
      loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])

    // Toolbar
    view.addSubview(toolbar)
    NSLayoutConstraint.activate([
      toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    ])

    let settingsButton = UIBarButtonItem(
      image: UIImage(systemName: "gearshape"),
      style: .plain,
      target: self,
      action: #selector(showSettings)
    )
    toolbar.items = [
      UIBarButtonItem.flexibleSpace(),
      settingsButton,
      UIBarButtonItem.flexibleSpace()
    ]

    // Paging label
    view.addSubview(pagingLabel)
    NSLayoutConstraint.activate([
      pagingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      pagingLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
      pagingLabel.heightAnchor.constraint(equalToConstant: 24),
      pagingLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
    ])

    let pagingTap = UITapGestureRecognizer(target: self, action: #selector(didTapPagingLabel))
    pagingLabel.addGestureRecognizer(pagingTap)
  }

  func setupNavigationBar() {
    let closeButton = UIBarButtonItem(
      image: UIImage(systemName: "xmark"),
      style: .plain,
      target: self,
      action: #selector(dismissReader)
    )
    navigationItem.leftBarButtonItem = closeButton
  }

  func bindViewModel() {
    viewModel.$state
      .map(\.loadingState)
      .removeDuplicates(by: { lhs, rhs in
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded): return true
        case let (.error(a), .error(b)): return a == b
        default: return false
        }
      })
      .receive(on: RunLoop.main)
      .sink { [weak self] loadingState in
        guard let self else { return }
        switch loadingState {
        case .idle: break
        case .loading:
          loadingIndicator.startAnimating()
        case .loaded:
          loadingIndicator.stopAnimating()
          collectionView.reloadData()
        case let .error(message):
          loadingIndicator.stopAnimating()
          title = message
        }
      }
      .store(in: &cancellable)

    viewModel.$state
      .map { (currentIndex: $0.currentIndex, totalPages: $0.totalPages) }
      .removeDuplicates { $0.currentIndex == $1.currentIndex && $0.totalPages == $1.totalPages }
      .receive(on: RunLoop.main)
      .sink { [weak self] values in
        guard let self, values.totalPages > 0 else { return }
        pagingLabel.text = "  \(values.currentIndex + 1)/\(values.totalPages)  "
      }
      .store(in: &cancellable)

    NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
      .sink { [weak self] _ in
        self?.viewModel.saveCurrentState()
      }
      .store(in: &cancellable)
  }

  func loadInitialData() {
    viewModel.send(.loadPage)

    if let textProvider = viewModel.dataProvider as? ReaderTextDataProvider {
      let canvasSize = textCanvasSize(for: view.bounds.size)
      textProvider.canvasSize = canvasSize
    }

    viewModel.send(.fetchContent)
  }

  // MARK: - Setup Methods

  private func setupCollectionView() {
    collectionView.backgroundColor = .clear
    collectionView.showsVerticalScrollIndicator = false
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.allowsSelection = false
    collectionView.scrollsToTop = false
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.register(ReaderPageCell.self, forCellWithReuseIdentifier: ReaderPageCell.identifier)
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.insetsLayoutMarginsFromSafeArea = false
    collectionView.preservesSuperviewLayoutMargins = false

    applyOptionsToCollectionView()

    tap.delegate = self
    tap.cancelsTouchesInView = false
    collectionView.addGestureRecognizer(tap)

    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    view.bringSubviewToFront(toolbar)
    view.bringSubviewToFront(pagingLabel)
  }

  // MARK: - Options

  func applyOptionsToCollectionView() {
    let options = viewModel.state.options
    collectionView.isPagingEnabled = options.transition == .paging
    collectionView.semanticContentAttribute = options.direction == .toLeft ? .forceRightToLeft : .forceLeftToRight
    collectionViewLayout.scrollDirection = options.direction == .toBottom ? .vertical : .horizontal

    if options.transition == .pageCurl || options.transition == .none {
      collectionView.isScrollEnabled = false
      let existingSwipes = collectionView.gestureRecognizers?.filter { $0 is UISwipeGestureRecognizer } ?? []
      for gesture in existingSwipes { collectionView.removeGestureRecognizer(gesture) }
      for direction in [UISwipeGestureRecognizer.Direction.left, .right, .up, .down] {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(manuallySwipeAction(_:)))
        gesture.direction = direction
        collectionView.addGestureRecognizer(gesture)
      }
    } else {
      collectionView.isScrollEnabled = true
      let swipeGestures = collectionView.gestureRecognizers?.filter { $0 is UISwipeGestureRecognizer } ?? []
      for gesture in swipeGestures { collectionView.removeGestureRecognizer(gesture) }
    }

    collectionViewInsetsUpdate()
    collectionView.reloadData()
    collectionView.layoutIfNeeded()
  }

  func collectionViewInsetsUpdate() {
    let options = viewModel.state.options
    if options.contentType == .text {
      if options.isFullScreenVerticalScroll {
        let insets = view.safeAreaInsets
        collectionView.contentInset = UIEdgeInsets(top: insets.top, left: 0, bottom: insets.bottom, right: 0)
      } else {
        collectionView.contentInset = .zero
      }
    } else {
      collectionView.contentInset = .zero
    }
  }

  // MARK: - Actions
  @objc private func dismissReader() {
    dismiss(animated: true)
  }
  
  @objc private func showSettings() {
    let settingsVC = ReaderSettingViewController(options: viewModel.state.options)
    settingsVC.settingCompletion = { [weak self] newOptions in
      self?.viewModel.send(.updateOptions(newOptions))
    }
    let nav = UINavigationController(rootViewController: settingsVC)

    if UIDevice.current.userInterfaceIdiom == .pad {
      nav.modalPresentationStyle = .popover
      nav.popoverPresentationController?.sourceView = toolbar
      nav.popoverPresentationController?.sourceRect = toolbar.bounds
    }
    present(nav, animated: true)
  }

  @objc private func didTapPagingLabel() {
    let totalPages = viewModel.state.totalPages
    guard totalPages > 0 else { return }

    let alert = UIAlertController(title: "Go to Page", message: "Enter page number (1-\(totalPages))", preferredStyle: .alert)
    alert.addTextField { textField in
      textField.keyboardType = .numberPad
      textField.placeholder = "Page number"
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Go", style: .default) { [weak self] _ in
      guard let text = alert.textFields?.first?.text, let page = Int(text),
            page >= 1, page <= totalPages else { return }
      self?.viewModel.send(.scrollTo(page - 1))
    })
    present(alert, animated: true)
  }

  // MARK: - Private Methods

  private func textCanvasSize(for viewSize: CGSize) -> CGSize {
    let options = viewModel.state.options
    if options.isFullScreenVerticalScroll {
      return viewSize
    }
    return CGSize(width: viewSize.width - 32, height: viewSize.height - 32)
  }
}
