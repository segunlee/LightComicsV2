import BookDomainInterface
import Combine
import Logger
import SharedUIComponents
import UIKit

// MARK: - BookShelfViewController

final class BookShelfViewController: UIViewController, ViewControllerLifecycle {
  // MARK: Properties

  let viewModel: BookShelfViewModel
  let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
  let refreshControl = UIRefreshControl()
  let activityIndicator = UIActivityIndicatorView(style: .large)
  var diffableDataSource: BookShelfDataSource?
  var cancellable: Set<AnyCancellable> = []
  var onSelectItem: ((ReadInfo) -> Void)?

  private var needsRefreshOnAppear = false

  // MARK: Initialization

  init(viewModel: BookShelfViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: ViewControllerLifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupCollectionView()
    configureDataSource()
    bindViewModel()
    loadInitialData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if needsRefreshOnAppear {
      needsRefreshOnAppear = false
      viewModel.send(.refresh)
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    needsRefreshOnAppear = true
  }

  func setupUI() {
    title = "서재"
    view.backgroundColor = .systemGroupedBackground

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.hidesWhenStopped = true
    view.addSubview(activityIndicator)
    NSLayoutConstraint.activate([
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }

  func setupCollectionView() {
    collectionView.setCollectionViewLayout(makeCollectionViewLayout(), animated: false)
    collectionView.backgroundColor = .clear
    collectionView.delegate = self
    collectionView.translatesAutoresizingMaskIntoConstraints = false

    collectionView.refreshControl = refreshControl
    refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  func bindViewModel() {
    viewModel.$state
      .dropFirst()
      .receive(on: RunLoop.main)
      .sink { [weak self] state in
        guard let self else { return }
        applySnapshot(sections: state.sections, itemsBySection: state.itemsBySection)
        refreshControl.endRefreshing()

        collectionView.restoreEmptyView()
        if !state.isLoading && state.allItems.isEmpty {
          if let error = state.errorMessage {
            collectionView.setEmptyView(.error(description: error))
          } else {
            collectionView.setEmptyView(.noData)
          }
        }
      }
      .store(in: &cancellable)

    viewModel.$state
      .map(\.isLoading)
      .removeDuplicates()
      .receive(on: RunLoop.main)
      .sink { [weak self] isLoading in
        if isLoading {
          self?.activityIndicator.startAnimating()
        } else {
          self?.activityIndicator.stopAnimating()
        }
      }
      .store(in: &cancellable)

    viewModel.toastEvent
      .receive(on: RunLoop.main)
      .sink { Toast.show($0) }
      .store(in: &cancellable)
  }

  func loadInitialData() {
    viewModel.send(.load)
  }

  // MARK: Actions

  @objc private func handleRefresh() {
    viewModel.send(.refresh)
  }
}
