import UIKit
import SharedUIComponents

// MARK: - FinderViewController + EditMode Associated Keys

@MainActor private var selectAllButtonKey: UInt8 = 0

extension FinderViewController {
  private var selectAllBarButton: UIBarButtonItem? {
    get { objc_getAssociatedObject(self, &selectAllButtonKey) as? UIBarButtonItem }
    set { objc_setAssociatedObject(self, &selectAllButtonKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  func updateEditMode() {
    tableView.setEditing(isEditMode, animated: true)
    navigationController?.tabBarController?.setTabBarHidden(isEditMode, animated: false)

    if isEditMode {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitEditMode))
      let selectAllButton = UIBarButtonItem(title: FinderStrings.editSelectAll, style: .plain, target: self, action: #selector(handleSelectAll))
      selectAllBarButton = selectAllButton
      navigationItem.leftBarButtonItems = [selectAllButton]
      navigationItem.rightBarButtonItems = [doneButton]
      setupToolbar()
    } else {
      selectAllBarButton = nil
      navigationItem.leftBarButtonItems = nil
      setupNavigationBar()
      navigationController?.setToolbarHidden(true, animated: true)
    }
  }

  func setupToolbar() {
    let moveButton = UIBarButtonItem(
      image: UIImage(systemName: "folder"),
      style: .plain,
      target: self,
      action: #selector(moveSelectedItems)
    )
    let deleteButton = UIBarButtonItem(
      image: UIImage(systemName: "trash"),
      style: .plain,
      target: self,
      action: #selector(deleteSelectedItems)
    )
    deleteButton.tintColor = .systemRed

    let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    toolbarItems = [
      flexSpace, moveButton,
      flexSpace, deleteButton,
      flexSpace
    ]

    navigationController?.setToolbarHidden(false, animated: true)
  }

  @objc func exitEditMode() {
    isEditMode = false
  }

  @objc func handleSelectAll() {
    let totalRows = (0 ..< tableView.numberOfSections).reduce(0) { $0 + tableView.numberOfRows(inSection: $1) }
    let selectedRows = tableView.indexPathsForSelectedRows?.count ?? 0

    if selectedRows == totalRows {
      for section in 0 ..< tableView.numberOfSections {
        for row in 0 ..< tableView.numberOfRows(inSection: section) {
          tableView.deselectRow(at: IndexPath(row: row, section: section), animated: false)
        }
      }
    } else {
      for section in 0 ..< tableView.numberOfSections {
        for row in 0 ..< tableView.numberOfRows(inSection: section) {
          tableView.selectRow(at: IndexPath(row: row, section: section), animated: false, scrollPosition: .none)
        }
      }
    }
    updateSelectAllButtonTitle()
  }

  func updateSelectAllButtonTitle() {
    let totalRows = (0 ..< tableView.numberOfSections).reduce(0) { $0 + tableView.numberOfRows(inSection: $1) }
    let selectedCount = tableView.indexPathsForSelectedRows?.count ?? 0
    selectAllBarButton?.title = (totalRows > 0 && selectedCount == totalRows)
      ? FinderStrings.editDeselectAll
      : FinderStrings.editSelectAll
  }

  @objc func moveSelectedItems() {
    guard let selectedRows = tableView.indexPathsForSelectedRows, !selectedRows.isEmpty else {
      Toast.show(.init(type: .warn, message: FinderStrings.editSelectToMove))
      return
    }

    let items = selectedRows.compactMap { diffableDataSource?.itemIdentifier(for: $0) }
    router.showDirSelection(for: items, currnetPath: self.viewModel.currentPath) { [weak self] destination in
      self?.viewModel.send(.move(items, destination: destination))
      self?.isEditMode = false
    }
  }

  @objc func deleteSelectedItems() {
    guard let selectedRows = tableView.indexPathsForSelectedRows, !selectedRows.isEmpty else {
      Toast.show(.init(type: .warn, message: FinderStrings.editSelectToDelete))
      return
    }

    let items = selectedRows.compactMap { diffableDataSource?.itemIdentifier(for: $0) }
    showDeleteConfirmation(for: items)
  }
}
