import UIKit

extension FinderDirSelectionViewController {
  func showCreateDirectoryAlert() {
    var alertTextField: UITextField?
    let alert = UIAlertController(title: FinderStrings.alertNewFolderTitle, message: nil, preferredStyle: .alert)
    alert.addTextField { textField in
      alertTextField = textField
      alertTextField?.placeholder = FinderStrings.alertNewFolderPlaceholder
    }

    let createAction = UIAlertAction(title: FinderStrings.alertCreate, style: .default) { [weak self] _ in
      guard let name = alertTextField?.text, !name.isEmpty else { return }
      self?.viewModel.send(.createDirectory(name))
    }
    let cancelAction = UIAlertAction(title: FinderStrings.alertCancel, style: .cancel)

    alert.addAction(createAction)
    alert.addAction(cancelAction)

    present(alert, animated: true)
  }
}
