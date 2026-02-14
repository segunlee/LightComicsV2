import Combine
import FinderFeatureInterface
import SharedUIComponents
import UIKit
import Logger

// MARK: - FinderViewController

final class FinderViewController: UIViewController, ViewControllerLifecycle {
  // MARK: - Properties

  let viewModel: FinderViewModel
  let router: FinderRouting
  let tableView = UITableView(frame: .zero, style: .insetGrouped)
  let searchController = UISearchController(searchResultsController: nil)
  let refreshControl = UIRefreshControl()
  let contextMenuButtonItem = UIBarButtonItem(image: nil, style: .plain, target: nil, action: nil)
  var diffableDataSource: FinderDataSource?
  let searchSubject = PassthroughSubject<String, Never>()
  var cancellable: Set<AnyCancellable> = []

  var isEditMode = false {
    didSet {
      updateEditMode()
    }
  }

  // MARK: - Initialization

  init(viewModel: FinderViewModel, router: FinderRouting) {
    self.viewModel = viewModel
    self.router = router
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupNavigationBar()
    setupTableView()
    configureDataSource()
    setupSearchController()
    bindViewModel()
    loadInitialData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let indexPath = tableView.indexPathForSelectedRow,
       let item = diffableDataSource?.itemIdentifier(for: indexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      viewModel.send(.reloadItem(item))
    }
  }

  // MARK: - ViewControllerLifecycle

  func setupUI() {
    view.backgroundColor = .systemGroupedBackground
    title = viewModel.state.title
  }

  func setupNavigationBar() {
    contextMenuButtonItem.image = UIImage(systemName: "ellipsis.circle")
    contextMenuButtonItem.accessibilityLabel = "Menu"
    contextMenuButtonItem.primaryAction = nil
    contextMenuButtonItem.menu = createNavigationContextMenu()
    navigationItem.rightBarButtonItem = contextMenuButtonItem
  }

  func bindViewModel() {
    viewModel.$state
      .dropFirst()
      .sink { [weak self] state in
        self?.tableView.restoreEmptyView()
        if state.items.isEmpty {
          self?.tableView.setEmptyView(state.searchQuery.isEmpty ? .noData : .noSearchResults)
        }

        if let error = state.errorMessage {
          self?.tableView.setEmptyView(.error(description: error))
        }

        self?.applySnapshot(
          directories: state.directories,
          files: state.files,
          animatingDifferences: !state.isPartialReload
        )
        self?.refreshControl.endRefreshing()
        self?.title = state.title
      }
      .store(in: &cancellable)

    searchSubject
      .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
      .removeDuplicates()
      .sink { [weak self] query in
        self?.viewModel.send(.search(query))
      }
      .store(in: &cancellable)

    NotificationCenter.default.publisher(for: .finderShouldRefresh)
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.viewModel.send(.load)
      }
      .store(in: &cancellable)
  }

  func loadInitialData() {
    viewModel.send(.load)
  }

  // MARK: - Setup Methods

  private func setupTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.delegate = self
    tableView.allowsMultipleSelectionDuringEditing = true
    tableView.insetsLayoutMarginsFromSafeArea = false
    tableView.insetsContentViewsToSafeArea = false
    tableView.contentInsetAdjustmentBehavior = .always
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

    refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    tableView.refreshControl = refreshControl

    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  private func setupSearchController() {
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search"
    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  // MARK: - Actions

  @objc private func handleRefresh() {
    viewModel.send(.load)
  }
}
