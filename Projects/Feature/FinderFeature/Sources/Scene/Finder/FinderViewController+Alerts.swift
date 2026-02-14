import FinderDomainInterface
import SharedUIComponents
import UIKit

extension FinderViewController {
  @MainActor
  func showCreateDirectoryAlert() {
    var alertTextField: UITextField?
    let alert = UIAlertController(title: "New Folder", message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
      alertTextField = textField
      alertTextField?.placeholder = "Folder Name"
    }

    let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
      guard let name = alertTextField?.text, !name.isEmpty else { return }
      self?.viewModel.send(.createDirectory(name))
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

    alert.addAction(createAction)
    alert.addAction(cancelAction)

    present(alert, animated: true)
  }

  @MainActor
  func showRenameAlert(for item: FileItem) {
    let alert = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
      textField.text = item.name
    }

    let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self, weak alert] _ in
      guard let newName = alert?.textFields?.first?.text, !newName.isEmpty else { return }
      self?.viewModel.send(.rename(item, newName))
      self?.isEditMode = false
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

    alert.addAction(renameAction)
    alert.addAction(cancelAction)

    present(alert, animated: true)
  }

  @MainActor
  func showDeleteConfirmation(for items: [FileItem]) {
    let message = items.count == 1 ? "Delete \(items[0].name)?" : "Delete \(items.count) items?"
    let alert = UIAlertController(title: "Confirm Delete", message: message, preferredStyle: .alert)

    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
      self?.viewModel.send(.delete(items))
      self?.isEditMode = false
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

    alert.addAction(deleteAction)
    alert.addAction(cancelAction)

    present(alert, animated: true)
  }

  @MainActor
  func showError(message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}
