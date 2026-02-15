import UIKit
import SharedUIComponents

extension FinderViewController {
  func updateEditMode() {
    tableView.setEditing(isEditMode, animated: true)
    navigationController?.tabBarController?.setTabBarHidden(isEditMode, animated: false)

    if isEditMode {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exitEditMode))
      let selectAllButton = UIBarButtonItem(title: FinderStrings.editSelectAll, style: .plain, target: self, action: #selector(handleSelectAll))
      navigationItem.leftBarButtonItems = [selectAllButton]
      navigationItem.rightBarButtonItems = [doneButton]
      setupToolbar()
    } else {
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
    for section in 0 ..< tableView.numberOfSections {
      for row in 0 ..< tableView.numberOfRows(inSection: section) {
        tableView.selectRow(at: IndexPath(row: row, section: section), animated: false, scrollPosition: .none)
      }
    }
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
