import Combine
import FinderDomainInterface
import SharedUIComponents
import UIKit

// MARK: - FinderDirSelectionViewController

@MainActor
final class FinderDirSelectionViewController: UIViewController, ViewControllerLifecycle {
  // MARK: - Properties

  let viewModel: DirSelectionViewModel
  let useCase: FinderUseCase
  let excludedPaths: Set<String>
  let onSelect: (String) -> Void
  let tableView = UITableView(frame: .zero, style: .insetGrouped)
  let contextMenuButtonItem = UIBarButtonItem(image: nil, style: .plain, target: nil, action: nil)
  var diffableDataSource: UITableViewDiffableDataSource<Int, FileItem>?
  var cancellable: Set<AnyCancellable> = []

  // MARK: - Initialization

  init(useCase: FinderUseCase, path: String, excludedPaths: Set<String>, onSelect: @escaping (String) -> Void) {
    self.useCase = useCase
    self.excludedPaths = excludedPaths
    self.onSelect = onSelect
    viewModel = DirSelectionViewModel(useCase: useCase, path: path, excludedPaths: excludedPaths)
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
    bindViewModel()
    loadInitialData()
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
    contextMenuButtonItem.menu = createContextMenu()

    let confirmButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "checkmark"),
      style: .done,
      target: self,
      action: #selector(confirmSelection)
    )
    confirmButtonItem.accessibilityLabel = "Move Here"

    navigationItem.rightBarButtonItems = [confirmButtonItem, contextMenuButtonItem]

    if navigationController?.viewControllers.first === self {
      navigationItem.leftBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .cancel,
        target: self,
        action: #selector(cancelSelection)
      )
    }
  }

  func bindViewModel() {
    viewModel.$state
      .dropFirst()
      .sink { [weak self] state in
        self?.applySnapshot(state.directories)
        self?.title = state.title
      }
      .store(in: &cancellable)
  }

  func loadInitialData() {
    viewModel.send(.load)
  }

  // MARK: - Private Methods

  private func setupTableView() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FolderCell")
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])
  }

  // MARK: - Actions

  @objc private func confirmSelection() {
    onSelect(viewModel.currentPath)
  }

  @objc private func cancelSelection() {
    dismiss(animated: true)
  }
}
