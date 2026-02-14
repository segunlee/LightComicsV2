import UIKit

extension FinderDirSelectionViewController {
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
}
